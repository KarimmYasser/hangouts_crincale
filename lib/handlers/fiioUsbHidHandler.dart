import 'dart:async';
import 'dart:typed_data';
import 'dart:math';

// Note: In a real Flutter/Dart application, you would use a package like
// 'flutter_hid' or 'hidapi' to get an actual HID device object.
// This class is a placeholder to represent such a device and make the code runnable.
class HidDevice {
  final StreamController<Uint8List> _inputReportController = StreamController.broadcast();

  /// A stream of incoming data reports from the HID device.
  Stream<Uint8List> get onInputReport => _inputReportController.stream;

  /// Sends an output report to the HID device.
  Future<void> sendReport(int reportId, Uint8List data) async {
    // This is where you would call the actual HID library's send/write method.
    print('Sending HID Report (ID: $reportId): $data');
    // For demonstration, we can simulate a response by adding to the input stream.
    // In a real scenario, the device itself would send data back.
    return Future.value();
  }

  // Helper method for simulation/testing to mimic the device sending data back.
  void simulateDeviceResponse(Uint8List data) {
    _inputReportController.add(data);
  }

  void dispose() {
    _inputReportController.close();
  }
}

// --- Data Models for Type Safety ---

/// Represents a single PEQ filter's properties.
class Filter {
  FilterType type;
  int freq;
  double q;
  double gain;
  bool disabled;

  Filter({
    this.type = FilterType.pk,
    this.freq = 1000,
    this.q = 1.0,
    this.gain = 0.0,
    this.disabled = true,
  });

  @override
  String toString() {
    return 'Filter(type: $type, freq: ${freq}Hz, q: $q, gain: ${gain}dB, disabled: $disabled)';
  }
}

/// Represents the configuration for a specific FiiO device model.
class ModelConfig {
  final double maxGain;
  final int maxFilters;
  final int reportId;
  final bool disconnectOnSave;
  final int disabledPresetId;

  ModelConfig({
    required this.maxGain,
    required this.maxFilters,
    required this.reportId,
    required this.disconnectOnSave,
    required this.disabledPresetId,
  });
}

/// Contains the device instance and its specific configuration.
class DeviceDetails {
  final HidDevice rawDevice;
  final ModelConfig modelConfig;
  final String? model;

  DeviceDetails({
    required this.rawDevice,
    required this.modelConfig,
    this.model,
  });
}

/// Enum for PEQ filter types for improved type safety.
enum FilterType { pk, lsq, hsq }


/// Manages communication and PEQ settings for FiiO USB HID devices.
class FiioUsbHid {
  // --- Protocol Constants ---
  static const int _peqFilterCount = 0x18;
  static const int _peqGlobalGain = 0x17;
  static const int _peqFilterParams = 0x15;
  static const int _peqPresetSwitch = 0x16;
  static const int _peqSaveToDevice = 0x19;
  // static const int _peqResetDevice = 0x1B; // Unused in original code
  // static const int _peqResetAll = 0x1C; // Unused in original code

  static const int _setHeader1 = 0xAA;
  static const int _setHeader2 = 0x0A;
  static const int _getHeader1 = 0xBB;
  static const int _getHeader2 = 0x0B;
  static const int _endHeaders = 0xEE;

  late final StreamSubscription<Uint8List> _inputReportSubscription;
  final Map<int, Completer<Uint8List>> _responseCompleters = {};

  /// Constructor initializes the listener for incoming device data.
  FiioUsbHid(HidDevice device) {
    // A single listener is set up to handle all incoming reports.
    // It dispatches data to the correct handler using completers.
    _inputReportSubscription = device.onInputReport.listen((data) {
      print('USB Device PEQ: onInputReport received data: $data');
      if (data.length > 4 && data[0] == _getHeader1 && data[1] == _getHeader2) {
        final command = data[4];
        if (_responseCompleters.containsKey(command)) {
          _responseCompleters.remove(command)!.complete(data);
        } else {
          print('USB Device PEQ: Unhandled data type: $command, data: $data');
        }
      }
    });
  }

  /// Disposes of the stream subscription to prevent memory leaks.
  void dispose() {
    _inputReportSubscription.cancel();
  }

  /// Pushes a full set of PEQ filters and settings to the device.
  Future<bool> pushToDevice(DeviceDetails deviceDetails, int slot, double preampGain, List<Filter> filters) async {
    try {
      final device = deviceDetails.rawDevice;
      final reportId = _getFiioReportId(deviceDetails);
      final maxFilters = deviceDetails.modelConfig.maxFilters;

      // Apply global gain. FiiO devices offset by maxGain, so we add it back.
      await _setGlobalGain(device, deviceDetails.modelConfig.maxGain + preampGain, reportId);

      final maxFiltersToUse = min(filters.length, maxFilters);
      await _setPeqCounter(device, maxFiltersToUse, reportId);
      await Future.delayed(const Duration(milliseconds: 100));

      for (int i = 0; i < maxFiltersToUse; i++) {
        final filter = filters[i];
        double gain = filter.disabled ? 0.0 : filter.gain;

        // Sanity checks
        if (filter.freq < 20 || filter.freq > 20000) filter.freq = 100;
        if (filter.q < 0.01 || filter.q > 100) filter.q = 1.0;

        await _setPeqParams(device, i, filter.freq, gain, filter.q, filter.type, reportId);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      await _saveToDevice(device, slot, reportId);
      print("PEQ filters pushed successfully.");

      return deviceDetails.modelConfig.disconnectOnSave;
    } catch (e) {
      print("Failed to push data to FiiO Device: $e");
      rethrow;
    }
  }

  /// Pulls the current PEQ settings from the device for a specific slot.
  /// NOTE: The original JS logic for this was complex and stateful. This version
  /// uses modern async Dart with Completers for a more robust implementation.
  Future<Map<String, dynamic>> pullFromDevice(DeviceDetails deviceDetails, int slot) async {
    try {
      final device = deviceDetails.rawDevice;
      final reportId = _getFiioReportId(deviceDetails);

      // Request all data points
      _getPeqCounter(device, reportId);
      final countData = await _waitForResponse(_peqFilterCount);
      final peqCount = _handlePeqCounter(countData);

      _getGlobalGain(device, reportId);
      final gainData = await _waitForResponse(_peqGlobalGain);
      final globalGain = _handleGain(gainData[6], gainData[7]);
      print('USB Device PEQ: Global gain received: ${globalGain}dB');

      final List<Filter> filters = List.filled(peqCount, Filter());
      for (int i = 0; i < peqCount; i++) {
        _getPeqParams(device, i, reportId);
        final paramsData = await _waitForResponse(_peqFilterParams);
        final filter = _handlePeqParams(paramsData);
        if (filter != null) {
          filters[paramsData[6]] = filter;
        }
      }

      return {
        'filters': filters,
        'globalGain': globalGain,
      };
    } catch (e) {
      print("Failed to pull data from FiiO Device: $e");
      rethrow;
    }
  }

  /// Gets the currently active PEQ slot on the device.
  Future<int> getCurrentSlot(DeviceDetails deviceDetails) async {
    try {
      final device = deviceDetails.rawDevice;
      final reportId = _getFiioReportId(deviceDetails);

      _getPresetPeq(device, reportId);
      final data = await _waitForResponse(_peqPresetSwitch, timeout: const Duration(seconds: 5));
      
      return _handleEqPreset(data, deviceDetails);
    } catch (e) {
      print("Failed to get current slot from FiiO Device: $e");
      rethrow;
    }
  }

  /// Enables or disables the PEQ by switching to a specific slot or the 'off' slot.
  Future<void> enablePEQ(DeviceDetails deviceDetails, bool enable, int slotId) async {
    final device = deviceDetails.rawDevice;
    final reportId = _getFiioReportId(deviceDetails);
    final presetId = enable ? slotId : deviceDetails.modelConfig.disabledPresetId;
    await _setPresetPeq(device, presetId, reportId);
  }

  // --- Private Helper Methods (Protocol Implementation) ---

  Future<Uint8List> _waitForResponse(int command, {Duration timeout = const Duration(seconds: 2)}) {
    final completer = Completer<Uint8List>();
    _responseCompleters[command] = completer;
    return completer.future.timeout(timeout, onTimeout: () {
      _responseCompleters.remove(command);
      throw TimeoutException("Timeout waiting for response for command 0x${command.toRadixString(16)}");
    });
  }

  int _getFiioReportId(DeviceDetails deviceDetails) {
    // Use the reportId from the model config if available.
    final reportId = deviceDetails.modelConfig.reportId;
    print('Using reportId $reportId for ${deviceDetails.model ?? "unknown device"}');
    return reportId;
  }

  Future<void> _setPeqParams(HidDevice device, int filterIndex, int fc, double gain, double q, FilterType filterType, int reportId) async {
    final freqBytes = _splitUnsignedValue(fc);
    final gainBytes = _fiioGainBytesFromValue(gain);
    final qFactorValue = (q * 100).round();
    final qFactorBytes = _splitUnsignedValue(qFactorValue);

    final packet = [
      _setHeader1, _setHeader2, 0, 0, _peqFilterParams, 8,
      filterIndex, gainBytes[0], gainBytes[1],
      freqBytes[0], freqBytes[1],
      qFactorBytes[0], qFactorBytes[1],
      _convertFromFilterType(filterType), 0, _endHeaders
    ];

    final data = Uint8List.fromList(packet);
    print('USB Device PEQ: setPeqParams() sending filter $filterIndex - Freq: ${fc}Hz, Gain: ${gain}dB, Q: $q, Type: $filterType, Data: $data');
    await device.sendReport(reportId, data);
  }
  
  Future<void> _setPresetPeq(HidDevice device, int presetId, int reportId) async {
    final packet = [_setHeader1, _setHeader2, 0, 0, _peqPresetSwitch, 1, presetId, 0, _endHeaders];
    final data = Uint8List.fromList(packet);
    print('USB Device PEQ: setPresetPeq() switching to preset $presetId, Data: $data');
    await device.sendReport(reportId, data);
  }

  Future<void> _setGlobalGain(HidDevice device, double gain, int reportId) async {
    final globalGain = (gain * 10).round();
    final gainBytes = _toBytePair(globalGain);

    final packet = [
      _setHeader1, _setHeader2, 0, 0, _peqGlobalGain, 2,
      gainBytes[1], gainBytes[0], 0, _endHeaders
    ];
    final data = Uint8List.fromList(packet);
    print('USB Device PEQ: setGlobalGain() setting global gain to ${gain}dB, Data: $data');
    await device.sendReport(reportId, data);
  }

  Future<void> _setPeqCounter(HidDevice device, int counter, int reportId) async {
    final packet = [
      _setHeader1, _setHeader2, 0, 0, _peqFilterCount, 1,
      counter, 0, _endHeaders
    ];
    final data = Uint8List.fromList(packet);
    print('USB Device PEQ: setPeqCounter() setting filter count to $counter, Data: $data');
    await device.sendReport(reportId, data);
  }
  
  Future<void> _saveToDevice(HidDevice device, int slotId, int reportId) async {
    final packet = [_setHeader1, _setHeader2, 0, 0, _peqSaveToDevice, 1, slotId, 0, _endHeaders];
    final data = Uint8List.fromList(packet);
    print('USB Device PEQ: saveToDevice() using reportId $reportId for slot $slotId, Data: $data');
    await device.sendReport(reportId, data);
  }

  void _getGlobalGain(HidDevice device, int reportId) {
    final packet = [_getHeader1, _getHeader2, 0, 0, _peqGlobalGain, 0, 0, _endHeaders];
    device.sendReport(reportId, Uint8List.fromList(packet));
  }

  void _getPeqCounter(HidDevice device, int reportId) {
    final packet = [_getHeader1, _getHeader2, 0, 0, _peqFilterCount, 0, 0, _endHeaders];
    device.sendReport(reportId, Uint8List.fromList(packet));
  }

  void _getPeqParams(HidDevice device, int filterIndex, int reportId) {
    final packet = [_getHeader1, _getHeader2, 0, 0, _peqFilterParams, 1, filterIndex, 0, _endHeaders];
    device.sendReport(reportId, Uint8List.fromList(packet));
  }

  void _getPresetPeq(HidDevice device, int reportId) {
    final packet = [_getHeader1, _getHeader2, 0, 0, _peqPresetSwitch, 0, 0, _endHeaders];
    device.sendReport(reportId, Uint8List.fromList(packet));
  }

  // --- Data Handling and Conversion Utilities ---
  
  int _handlePeqCounter(Uint8List data) {
    int peqCount = data[6];
    print("PEQ Counter from device: $peqCount");
    return peqCount;
  }

  Filter? _handlePeqParams(Uint8List data) {
    if (data.length < 14) return null;
    final filterIndex = data[6];
    final gain = _handleGain(data[7], data[8]);
    final frequency = _combineBytes(data[9], data[10]);
    final qFactor = (_combineBytes(data[11], data[12])) / 100.0;
    final filterType = _convertToFilterType(data[13]);

    print('Filter $filterIndex: Gain=$gain, Frequency=$frequency, Q=$qFactor, Type=$filterType');

    return Filter(
      type: filterType,
      freq: frequency,
      q: (qFactor == 0) ? 1.0 : qFactor, // Ensure Q is not zero
      gain: gain,
      disabled: gain == 0.0 && frequency == 0 && qFactor == 0.0,
    );
  }

  int _handleEqPreset(Uint8List data, DeviceDetails deviceDetails) {
    final presetId = data[6];
    print("EQ Preset ID from device: $presetId");
    if (presetId == deviceDetails.modelConfig.disabledPresetId) {
      return -1; // -1 represents 'Off'
    }
    return presetId;
  }

  int _convertFromFilterType(FilterType filterType) {
    switch (filterType) {
      case FilterType.pk: return 0;
      case FilterType.lsq: return 1;
      case FilterType.hsq: return 2;
    }
  }

  FilterType _convertToFilterType(int datum) {
    switch (datum) {
      case 0: return FilterType.pk;
      case 1: return FilterType.lsq;
      case 2: return FilterType.hsq;
      default: return FilterType.pk;
    }
  }

  double _handleGain(int lowByte, int highByte) {
    int combined = _combineBytes(lowByte, highByte);
    // Check if the sign bit (15) is set
    if ((combined & 0x8000) != 0) {
      // Negative number, perform two's complement
      return ((~combined & 0xFFFF) + 1) * -1 / 10.0;
    }
    return combined / 10.0;
  }
  
  /// Converts a gain value (e.g., -12.5) to a two-byte array for the FiiO protocol.
  List<int> _fiioGainBytesFromValue(double gain) {
    int val = (gain * 10).round();
    if (val < 0) {
      // Two's complement for negative numbers
      val = (~val.abs() & 0xFFFF) + 1;
    }
    return [(val >> 8) & 0xFF, val & 0xFF];
  }

  List<int> _toBytePair(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  List<int> _splitUnsignedValue(int value) {
    return [(value >> 8) & 0xFF, value & 0xFF];
  }

  int _combineBytes(int highByte, int lowByte) {
    return (highByte << 8) | lowByte;
  }
}

// --- Example Usage ---
void main() async {
  // 1. Setup a mock device and its configuration
  final mockDevice = HidDevice();
  final deviceDetails = DeviceDetails(
    rawDevice: mockDevice,
    model: 'FiiO KA17',
    modelConfig: ModelConfig(
      maxGain: -12.0,
      maxFilters: 10,
      reportId: 7,
      disconnectOnSave: false,
      disabledPresetId: 4, // Example value
    ),
  );

  final fiioController = FiioUsbHid(mockDevice);

  // 2. Example: Get the current slot
  print('\n--- Getting Current Slot ---');
  try {
    // Start the operation
    final slotFuture = fiioController.getCurrentSlot(deviceDetails);
    
    // Simulate the device responding after a short delay
    await Future.delayed(Duration(milliseconds: 50));
    mockDevice.simulateDeviceResponse(Uint8List.fromList([0xBB, 0x0B, 0, 0, 0x16, 1, 2, 0, 0xEE])); // Responding with slot 2
    
    final currentSlot = await slotFuture;
    print('SUCCESS: Current active slot is: $currentSlot');
  } catch (e) {
    print('ERROR getting slot: $e');
  }

  // 3. Example: Push new settings to the device
  print('\n--- Pushing Settings to Slot 0 ---');
  final filtersToPush = [
    Filter(type: FilterType.pk, freq: 100, q: 0.7, gain: -3.0, disabled: false),
    Filter(type: FilterType.hsq, freq: 5000, q: 1.2, gain: 2.5, disabled: false),
  ];
  
  await fiioController.pushToDevice(deviceDetails, 0, -2.0, filtersToPush);
  print('SUCCESS: Pushed settings to device.');

  fiioController.dispose();
  mockDevice.dispose();
}

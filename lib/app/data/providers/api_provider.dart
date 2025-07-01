import 'dart:math';
import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../models/phone_model.dart';
import '../models/frequency_response.dart';

/// A mock API provider that simulates fetching data from a network source.
class ApiProvider {
  // A predefined list of colors to assign to new graph curves.
  final List<Color> _colorCycle = [
    Colors.blue[700]!,
    Colors.red[700]!,
    Colors.green[700]!,
    Colors.orange[700]!,
    Colors.purple[700]!,
    Colors.teal[700]!,
    Colors.pink[700]!,
    Colors.amber[700]!,
  ];
  int _colorIndex = 0;

  /// Fetches a list of all brands.
  Future<List<Brand>> fetchBrands() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Brand(id: 'sennheiser', name: 'Sennheiser'),
      Brand(id: 'beyerdynamic', name: 'Beyerdynamic'),
      Brand(id: 'hifiman', name: 'HifiMAN'),
      Brand(id: 'moondrop', name: 'Moondrop'),
      Brand(id: 'sony', name: 'Sony'),
    ];
  }

  /// Fetches a list of all models. In a real app, you might fetch models per brand.
  Future<List<PhoneModel>> fetchAllModels() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      PhoneModel(id: 'hd650', name: 'HD 650', brandId: 'sennheiser'),
      PhoneModel(id: 'hd800s', name: 'HD 800 S', brandId: 'sennheiser'),
      PhoneModel(id: 'dt990', name: 'DT 990 Pro', brandId: 'beyerdynamic'),
      PhoneModel(id: 'sundara', name: 'Sundara', brandId: 'hifiman'),
      PhoneModel(id: 'aria', name: 'Aria', brandId: 'moondrop'),
      PhoneModel(id: 'kato', name: 'Kato', brandId: 'moondrop'),
      PhoneModel(id: 'wh1000xm5', name: 'WH-1000XM5', brandId: 'sony'),
    ];
  }

  /// Fetches the detailed frequency response data for a given model ID.
  Future<FrequencyResponse> fetchFrequencyResponse(PhoneModel model) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get the next color in the cycle.
    final color = _colorCycle[_colorIndex];
    _colorIndex++;
    _colorIndex %= _colorCycle.length;

    // Generate pseudo-realistic mock data based on the model ID.
    return FrequencyResponse(
      id: model.id,
      name: '${model.name} (${model.brandId})', // More descriptive name
      brandID: model.brandId,
      data: _generateMockFRData(model.id),
      color: color,
    );
  }

  /// A private helper to generate unique-looking mock data for different models.
  List<DataPoint> _generateMockFRData(String modelId) {
    final random = Random(
      modelId.hashCode,
    ); // Seed random with model ID for consistency
    final List<DataPoint> data = [];
    double currentDb = 85.0;

    for (double freq = 20; freq <= 20000; freq *= 1.05) {
      // Add some randomness and model-specific characteristics
      double dbChange = (random.nextDouble() - 0.5) * 2.0;

      // Simulate bass roll-off/hump
      if (freq < 200) {
        dbChange += (modelId.contains('hd') ? -0.2 : 0.3);
      }

      // Simulate "ear gain" peak
      if (freq > 2000 && freq < 5000) {
        dbChange += (sin((freq - 2000) / 3000 * pi) * 3);
      }

      // Simulate treble variations
      if (freq > 6000) {
        dbChange += (random.nextDouble() - 0.5) * 2.5;
        dbChange -= (modelId.length % 2 == 0 ? 0.1 : -0.1);
      }

      currentDb += dbChange;
      data.add(DataPoint(frequency: freq, db: currentDb));
    }
    return data;
  }
}

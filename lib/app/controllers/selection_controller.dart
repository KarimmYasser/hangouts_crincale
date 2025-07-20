import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../data/models/brand.dart';
import '../data/models/frequency_response.dart';
import '../data/models/phone_model.dart';
import 'graph_controller.dart';

// Enum to control which list (Brands or Models) is currently active.
enum SelectionTab { brands, models }

class SelectionController extends GetxController {
  final GraphController graphController = Get.find();

  // The master lists of all available brands and models.
  final RxList<Brand> allBrands = <Brand>[].obs;
  final RxList<PhoneModel> allModels = <PhoneModel>[].obs;

  // The filtered lists displayed in the UI based on search queries.
  final RxList<Brand> filteredBrands = <Brand>[].obs;
  final RxList<PhoneModel> filteredModels = <PhoneModel>[].obs;

  // The currently selected brand.
  final Rx<Brand?> selectedBrand = Rx<Brand?>(null);

  // The active tab in the selection panel.
  final Rx<SelectionTab> activeTab = SelectionTab.brands.obs;

  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Populate the lists when the controller is initialized.
    // In a real app, this would come from an API call.
    _fetchData();
    // Listen to changes in the search query to apply filtering.
    debounce(
      searchQuery,
      (_) => _filterLists(),
      time: const Duration(milliseconds: 300),
    );
  }

  void _fetchData() async {
    // Load data from JSON
    final String jsonString = await rootBundle.loadString(
      'assets/phones/phone_book.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);

    // Parse Brands
    allBrands.assignAll(
      jsonList.map((brandJson) {
        return Brand(
          id: brandJson['name'].toString(),
          name: brandJson['name'] as String,
          suffix: brandJson['suffix'] as String?,
        );
      }).toList(),
    );

    // Parse PhoneModels
    List<PhoneModel> phoneModels = [];
    for (var brandJson in jsonList) {
      String brandId = brandJson['name'].toString();
      List<dynamic> phones = brandJson['phones'] as List<dynamic>;
      phoneModels.addAll(
        phones.map((phoneJson) {
          return PhoneModel.fromJson(
            phoneJson as Map<String, dynamic>,
            phoneJson['name'].toString(),
            brandId,
          );
        }).toList(),
      );
    }
    allModels.assignAll(phoneModels);

    _filterLists();
  }

  /// Filters the brand and model lists based on the current search query and selected brand.
  void _filterLists() {
    if (searchQuery.isEmpty) {
      filteredBrands.assignAll(allBrands);
      // If a brand is selected, show only its models. Otherwise, show all.
      if (selectedBrand.value != null) {
        filteredModels.assignAll(
          allModels.where((m) => m.brandId == selectedBrand.value!.id).toList(),
        );
      } else {
        filteredModels.assignAll(allModels);
      }
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredBrands.assignAll(
        allBrands.where((b) => b.name.toLowerCase().contains(query)),
      );
      filteredModels.assignAll(
        allModels.where((m) => m.name.toLowerCase().contains(query)),
      );
    }
  }

  /// Selects a brand and updates the model list accordingly.
  void selectBrand(Brand brand) {
    selectedBrand.value = brand;
    activeTab.value = SelectionTab.models; // Switch to the models tab.
    _filterLists(); // Update the model list.
  }

  /// Selects a model, fetches its FR data, and adds it to the graph.
  void selectModel(PhoneModel model) async {
    final bool isModelLoaded = graphController.curves.any(
      (curve) => curve.id.startsWith(model.id),
    );

    if (isModelLoaded) {
      graphController.curves.removeWhere(
        (curve) => curve.id.startsWith(model.id),
      );
      if (graphController.baselineCurve.value != null &&
          graphController.baselineCurve.value!.id.startsWith(model.id)) {
        graphController.baselineCurve.value = null;
      }
    } else {
      if (model.file != null && model.file!.isNotEmpty) {
        final baseFileName = model.file![0];
        final color = _getRandomDarkColor();

        try {
          final leftData = await _loadDataFromFile('$baseFileName L.txt');
          final rightData = await _loadDataFromFile('$baseFileName R.txt');

          // Add Left and Right curves
          if (graphController.curves.isEmpty) {
            final leftCurve = FrequencyResponse(
              id: '${model.id} (L)',
              name: '${model.name} (L)',
              brandID: model.brandId,
              data: leftData,
              color: _getRandomDarkColor(),
            );
            graphController.addCurve(leftCurve);

            final rightCurve = FrequencyResponse(
              id: '${model.id} (R)',
              name: '${model.name} (R)',
              brandID: model.brandId,
              data: rightData,
              color: _getRandomDarkColor(),
            );
            graphController.addCurve(rightCurve);
          } else {
            // Add Average curve
            if (leftData.isNotEmpty && rightData.isNotEmpty) {
              final averageData = _calculateAverageData(leftData, rightData);
              final averageCurve = FrequencyResponse(
                id: '${model.id} (Avg)',
                name: '${model.name} (Avg)',
                brandID: model.brandId,
                data: averageData,
                color: _getRandomDarkColor(),
              );
              graphController.addCurve(averageCurve);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading files for ${model.name}: $e');
          }
        }
      }
    }
    filteredModels.refresh();
  }

  List<DataPoint> _calculateAverageData(
    List<DataPoint> data1,
    List<DataPoint> data2,
  ) {
    List<DataPoint> averageData = [];
    final int length = min(data1.length, data2.length);
    for (int i = 0; i < length; i++) {
      // Assuming frequencies align
      if (data1[i].frequency == data2[i].frequency) {
        final avgDb = (data1[i].db + data2[i].db) / 2;
        averageData.add(DataPoint(frequency: data1[i].frequency, db: avgDb));
      }
    }
    return averageData;
  }

  /// Loads and parses frequency response data from a given asset file.
  Future<List<DataPoint>> _loadDataFromFile(String fileName) async {
    final String fileContent = await rootBundle.loadString(
      'assets/data/$fileName',
    );
    final List<DataPoint> dataPoints = [];
    final lines = fileContent.split('\n');

    for (final line in lines) {
      // Skip header lines and empty lines
      if (line.startsWith('*') || line.trim().isEmpty) {
        continue;
      }

      final parts = line.split(RegExp(r'[,\s]+'));
      if (parts.length >= 2) {
        final frequency = double.tryParse(parts[0]);
        final db = double.tryParse(parts[1]);

        if (frequency != null && db != null) {
          dataPoints.add(DataPoint(frequency: frequency, db: db));
        }
      }
    }
    return dataPoints;
  }

  /// Changes the active selection tab.
  void setTab(SelectionTab tab) {
    activeTab.value = tab;
  }

  /// Clears the selected brand and returns to the brands tab.
  void clearBrandSelection() {
    selectedBrand.value = null;
    activeTab.value = SelectionTab.models;
    _filterLists(); // Re-filter to show all models
  }

  Color _getRandomDarkColor() {
    final random = Random();
    // Generate a random HSL color with low saturation and lightness for a dark color
    return HSLColor.fromAHSL(
      1.0, // Alpha
      random.nextDouble() * 360, // Hue
      0.4 + random.nextDouble() * 0.2, // Saturation (0.4-0.6)
      0.2 + random.nextDouble() * 0.2, // Lightness (0.2-0.4)
    ).toColor();
  }
}

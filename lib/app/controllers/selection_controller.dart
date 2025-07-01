import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../data/models/brand.dart';
import '../data/models/phone_model.dart';
import '../data/models/frequency_response.dart';
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
      time: Duration(milliseconds: 300),
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
  void selectModel(PhoneModel model, {Color color = Colors.red}) {
    if (graphController.curves.any((curve) => curve.id == model.id)) {
      graphController.removeCurve(model.id);
    } else {
      // In a real app, you would now fetch the detailed FR data for this model.
      // For this example, we'll create some dummy data.
      final dummyData = List.generate(
        100,
        (i) => DataPoint(frequency: 20.0 + i * 200, db: -5 + (i % 10) - 5),
      );
      final newCurve = FrequencyResponse(
        id: model.id,
        name: model.name,
        brandID: model.brandId,
        data: dummyData,
        color: _getRandomDarkColor(),
      );
      graphController.addCurve(newCurve);
    }
    filteredModels.refresh();
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

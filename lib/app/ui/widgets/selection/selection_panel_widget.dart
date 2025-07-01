import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/selection_controller.dart';
import 'search_bar_widget.dart';
import 'selected_model_item_widget.dart';

class SelectionPanelWidget extends StatelessWidget {
  const SelectionPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SelectionController>();

    return Column(
      children: [
        const SearchBarWidget(),
        Obx(
          () => SegmentedButton<SelectionTab>(
            segments: const <ButtonSegment<SelectionTab>>[
              ButtonSegment<SelectionTab>(
                value: SelectionTab.brands,
                label: Text('Brands'),
                icon: Icon(Icons.business_center_outlined),
              ),
              ButtonSegment<SelectionTab>(
                value: SelectionTab.models,
                label: Text('Models'),
                icon: Icon(Icons.headphones_outlined),
              ),
            ],
            selected: <SelectionTab>{controller.activeTab.value},
            onSelectionChanged: (Set<SelectionTab> newSelection) {
              controller.setTab(newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            // Use a switch statement to show the correct list
            switch (controller.activeTab.value) {
              case SelectionTab.brands:
                if (controller.filteredBrands.isEmpty) {
                  return const Center(child: Text("No brands found."));
                }
                return ListView.builder(
                  itemCount: controller.filteredBrands.length,
                  itemBuilder: (context, index) {
                    final brand = controller.filteredBrands[index];
                    return ListTile(
                      title: Text(brand.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => controller.selectBrand(brand),
                    );
                  },
                );
              case SelectionTab.models:
                if (controller.filteredModels.isEmpty) {
                  return const Center(child: Text("No models found."));
                }
                return ListView.builder(
                  itemCount: controller.filteredModels.length,
                  itemBuilder: (context, index) {
                    final model = controller.filteredModels[index];
                    if (controller.graphController.curves.any(
                      (curve) => curve.id == model.id,
                    )) {
                      return SelectedModelItemWidget(model: model);
                    }
                    return ListTile(
                      title: Text(model.name),
                      subtitle:
                          controller.selectedBrand.value == null
                              ? Text(model.brandId.capitalizeFirst ?? '')
                              : null,
                      trailing: Icon(
                        Icons.add,
                        color: Theme.of(context).primaryColor,
                      ),
                      onTap: () => controller.selectModel(model),
                    );
                  },
                );
            }
          }),
        ),
        Obx(() {
          if (controller.activeTab.value == SelectionTab.models &&
              controller.selectedBrand.value != null) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ActionChip(
                avatar: const Icon(Icons.arrow_circle_right),
                label: Text("All Models"),
                onPressed: () => controller.clearBrandSelection(),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/equalizer_controller.dart';
import '../../../controllers/graph_controller.dart';
import 'auto_eq_widget.dart';
import 'eq_demo_widget.dart';
import 'parametric_eq_widget.dart';

class EqualizerPanelWidget extends StatelessWidget {
  const EqualizerPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final EqualizerController eqCtrl = Get.find();
    final GraphController graphCtrl = Get.find();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Model Selection ---
          Text("Target Model", style: theme.textTheme.titleSmall),
          Obx(
            () => DropdownButtonFormField(
              value: eqCtrl.eqTargetModel.value,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Choose a model to EQ",
              ),
              items:
                  graphCtrl.curves.map((curve) {
                    return DropdownMenuItem(
                      value: curve,
                      child: Text(curve.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
              onChanged: (curve) {
                eqCtrl.eqTargetModel.value = curve;
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- Pre-amp Display ---
          Obx(
            () => Text(
              "Pre-amp: ${eqCtrl.preAmp.value.toStringAsFixed(1)} dB",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),

          // --- Filters List ---
          Obx(
            () => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eqCtrl.filters.length,
              itemBuilder:
                  (context, index) => ParametricEqWidget(
                    filterIndex: index,
                    key: ValueKey(eqCtrl.filters[index]),
                  ),
            ),
          ),
          const SizedBox(height: 8),

          // --- Filter Action Buttons ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Add Filter",
                onPressed: eqCtrl.addFilter,
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: "Remove Last Filter",
                onPressed: eqCtrl.removeFilter,
              ),
              IconButton(
                icon: const Icon(Icons.sort_by_alpha),
                tooltip: "Sort by Frequency",
                onPressed: eqCtrl.sortFilters,
              ),
              TextButton(
                onPressed: () => eqCtrl.toggleAllFilters(false),
                child: const Text("Disable All"),
              ),
            ],
          ),
          const Divider(height: 24),

          // --- AutoEQ Section ---
          const AutoEqWidget(),
          const Divider(height: 24),

          // --- EQ Demo Section ---
          const EqDemoWidget(),
          const Divider(height: 24),

          // --- Import/Export Buttons ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text("Import EQ")),
              ElevatedButton(onPressed: () {}, child: const Text("Export EQ")),
            ],
          ),
        ],
      ),
    );
  }
}

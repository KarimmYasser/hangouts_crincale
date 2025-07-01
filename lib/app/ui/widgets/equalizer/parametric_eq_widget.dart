import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/equalizer_controller.dart';
import '../../../data/models/eq_filter.dart';
import '../../../services/custom_text_field.dart';

class ParametricEqWidget extends StatelessWidget {
  final int filterIndex;
  const ParametricEqWidget({super.key, required this.filterIndex});

  @override
  Widget build(BuildContext context) {
    final EqualizerController controller = Get.find();
    final EqFilter filter = controller.filters[filterIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Checkbox(
                  value: filter.isEnabled,
                  onChanged:
                      (val) =>
                          controller.updateFilter(filterIndex, isEnabled: val),
                  visualDensity: VisualDensity.compact,
                ),
                DropdownButton<FilterType>(
                  value: filter.type,
                  onChanged: (FilterType? newType) {
                    if (newType != null) {
                      controller.updateFilter(filterIndex, type: newType);
                    }
                  },
                  items:
                      FilterType.values.map<DropdownMenuItem<FilterType>>((
                        FilterType value,
                      ) {
                        return DropdownMenuItem<FilterType>(
                          value: value,
                          child: Text(value.name),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Freq, Gain, Q TextFields
          CustomTextField(
            label: "Freq",
            value: filter.freq.toString(),
            onUpdate:
                (val) => controller.updateFilter(
                  filterIndex,
                  freq: double.tryParse(val),
                ),
          ),
          const SizedBox(width: 8),
          CustomTextField(
            label: "Gain",
            value: filter.gain.toString(),
            onUpdate:
                (val) => controller.updateFilter(
                  filterIndex,
                  gain: double.tryParse(val),
                ),
          ),
          const SizedBox(width: 8),
          CustomTextField(
            label: "Q",
            value: filter.q.toString(),
            onUpdate:
                (val) => controller.updateFilter(
                  filterIndex,
                  q: double.tryParse(val),
                ),
          ),
        ],
      ),
    );
  }
}

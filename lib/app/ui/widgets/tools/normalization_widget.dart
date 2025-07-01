import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/graph_controller.dart';

class NormalizationWidget extends StatefulWidget {
  const NormalizationWidget({super.key});

  @override
  State<NormalizationWidget> createState() => _NormalizationWidgetState();
}

class _NormalizationWidgetState extends State<NormalizationWidget> {
  final GraphController controller = Get.find();
  late final TextEditingController _dbController;
  late final TextEditingController _hzController;

  @override
  void initState() {
    super.initState();
    _dbController = TextEditingController(
      text: controller.normDb.value.toString(),
    );
    _hzController = TextEditingController(
      text: controller.normHz.value.toString(),
    );
  }

  @override
  void dispose() {
    _dbController.dispose();
    _hzController.dispose();
    super.dispose();
  }

  void _updateNormalization() {
    final double? db = double.tryParse(_dbController.text);
    final double? hz = double.tryParse(_hzController.text);
    if (db != null && hz != null) {
      controller.setNormalization(db, hz);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Normalize",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  "Make all curves match at a specific frequency and dB level.",
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              child: TextField(
                controller: _dbController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: const InputDecoration(
                  labelText: "dB",
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: _updateNormalization,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _hzController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Hz",
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: _updateNormalization,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/selection_controller.dart';
import '../../../data/models/phone_model.dart';

class SelectedModelItemWidget extends StatelessWidget {
  SelectedModelItemWidget({super.key, required this.model});

  final PhoneModel model;
  final controller = Get.find<SelectionController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      decoration: BoxDecoration(
        color:
            (model.reviewScore ?? 'Untested').toLowerCase() != 'approved'
                ? Theme.of(context).primaryColor
                : Colors.orange[700],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 4),
              Text(
                model.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.selectModel(model),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                ((model.reviewScore ?? 'Untested').toLowerCase() == 'approved'
                    ? '✅ Approved'
                    : (model.reviewScore ?? 'Untested').toLowerCase() ==
                        'tested'
                    ? '🌡️ Tested'
                    : '❓ Untested'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              Text(
                model.price ?? 'Discont.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

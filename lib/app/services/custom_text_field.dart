import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onUpdate,
  });

  final String label;
  final String value;
  final Function(String) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?[\d.]*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        onChanged: onUpdate,
      ),
    );
  }
}

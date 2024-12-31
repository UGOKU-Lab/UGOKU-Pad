import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import '../../bluetooth/constants.dart';

class ColorSelector extends ConsumerWidget {

  final String? initialValue;
  final void Function(String?)? onChanged;

  const ColorSelector({
    super.key,
    this.initialValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    Color selectedColor = hexToColor(initialValue);

    return StatefulBuilder(
      builder: (context, setState) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColorPicker(
                enableShadesSelection: false,
                color: selectedColor,
                columnSpacing: 16,
                spacing: 8,
                runSpacing: 8,
                onColorChanged: (Color color) {
                  setState(() {
                    selectedColor = color;
                  });
                  onChanged?.call(selectedColor.hex);
                },
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.wheel: true // Enable color wheel
                },
              ),
              //const SizedBox(height: 20),
              Text(
                'Selected Color: ${selectedColor.hex}',
                style: TextStyle(
                  color: selectedColor,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

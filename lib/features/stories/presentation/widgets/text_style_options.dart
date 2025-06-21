// lib/features/stories/presentation/widgets/text_style_options.dart
import 'package:flutter/material.dart';

class TextStyleOptions extends StatelessWidget {
  final double fontSize;
  final String fontWeight;
  final Function(double) onFontSizeChanged;
  final Function(String) onFontWeightChanged;

  const TextStyleOptions({
    super.key,
    required this.fontSize,
    required this.fontWeight,
    required this.onFontSizeChanged,
    required this.onFontWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Font size slider
        Row(
          children: [
            const Text('Size: ', style: TextStyle(color: Colors.white)),
            Expanded(
              child: Slider(
                value: fontSize,
                min: 12.0,
                max: 48.0,
                divisions: 36,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.grey,
                onChanged: onFontSizeChanged,
              ),
            ),
            Text(
              fontSize.round().toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Font weight options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFontWeightButton(context, 'Light', 'light', FontWeight.w300),
            _buildFontWeightButton(
              context,
              'Normal',
              'normal',
              FontWeight.normal,
            ),
            _buildFontWeightButton(context, 'Bold', 'bold', FontWeight.bold),
          ],
        ),
      ],
    );
  }

  Widget _buildFontWeightButton(
    BuildContext context,
    String label,
    String value,
    FontWeight weight,
  ) {
    final isSelected = fontWeight == value;

    return GestureDetector(
      onTap: () => onFontWeightChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }
}

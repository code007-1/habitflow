import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/core/colors.dart';

class MultiSelectButtons extends StatefulWidget {
  final List<String> options;
  final void Function(int) onOptionSelected;
  const MultiSelectButtons({
    super.key,
    required this.options,
    required this.onOptionSelected,
  });

  @override
  State<MultiSelectButtons> createState() => _MultiSelectButtonsState();
}

class _MultiSelectButtonsState extends State<MultiSelectButtons> {
  int _selectedIndex = 0; // 0 = Daily, 1 = Weekly, 2 = Custom

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.options.length, (index) {
        final isSelected = _selectedIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
                widget.onOptionSelected(index);
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                right: index < widget.options.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey3,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(30), // Pill shape
              ),
              child: Center(
                child: Text(
                  widget.options[index],
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.grey6,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

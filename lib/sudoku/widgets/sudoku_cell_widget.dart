import 'package:flutter/material.dart';

import '../models/sudoku_cell.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final VoidCallback onTap;

  const SudokuCellWidget({super.key, required this.cell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;

    if (cell.selected) {
      backgroundColor = Colors.amber.shade200;
    } else if (cell.fixed) {
      backgroundColor = Colors.grey.shade300;
    } else {
      backgroundColor = Colors.white;
    }

    Color textColor;

    if (cell.error) {
      textColor = Colors.red;
    } else if (cell.fixed) {
      textColor = Colors.black;
    } else {
      textColor = Colors.blue;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: cell.value == 0
            ? const SizedBox.shrink()
            : Text(
                cell.value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

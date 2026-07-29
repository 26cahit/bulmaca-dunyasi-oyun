import 'package:flutter/material.dart';

class KeyboardWidget extends StatelessWidget {
  final Function(String) onKeyPressed;
  final Set<String> usedLetters;
  final String currentWord;
  const KeyboardWidget({
    super.key,
    required this.onKeyPressed,
    required this.usedLetters,
    required this.currentWord,
  });
  static const List<String> letters = [
    "A",
    "B",
    "C",
    "Ç",
    "D",
    "E",
    "F",
    "G",
    "Ğ",
    "H",
    "I",
    "İ",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "Ö",
    "P",
    "R",
    "S",
    "Ş",
    "T",
    "U",
    "Ü",
    "V",
    "Y",
    "Z",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Wrap(
        spacing: 6,
        runSpacing: 6,

        alignment: WrapAlignment.center,

        children: letters.map((letter) {
          Color buttonColor = const Color(0xFF1E293B);

          if (usedLetters.contains(letter)) {
            if (currentWord.contains(letter)) {
              buttonColor = Colors.green;
            } else {
              buttonColor = Colors.red;
            }
          }
          return ElevatedButton(
            onPressed: () {
              onKeyPressed(letter);
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            child: Text(
              letter,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}

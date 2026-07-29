import 'package:flutter/material.dart';

class WheelButton extends StatelessWidget {
  final VoidCallback onSpin;
  final bool spinning;

  const WheelButton({super.key, required this.onSpin, required this.spinning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,

      child: ElevatedButton(
        onPressed: spinning ? null : onSpin,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: const CircleBorder(),
          elevation: 8,
        ),

        child: FittedBox(
          child: Text(
            spinning ? "DÖNÜYOR" : "DÖNDÜR",

            textAlign: TextAlign.center,

            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
    );
  }
}

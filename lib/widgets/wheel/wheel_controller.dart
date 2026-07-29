import 'package:flutter/material.dart';

class WheelController extends ChangeNotifier {
  double rotation = 0;

  bool isSpinning = false;

  String selectedLetter = "";

  void reset() {
    rotation = 0;
    isSpinning = false;
    selectedLetter = "";
    notifyListeners();
  }
}
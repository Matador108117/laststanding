import 'package:flutter/material.dart';

class MyAppState extends ChangeNotifier {
  var token = "";
  var username = "";
  var error = "";
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int value) {
    if (_selectedIndex != value) {
      _selectedIndex = value;
      notifyListeners(); // ✅ fuerza actualización de UI
    }
  }

  var userId = 0;
}

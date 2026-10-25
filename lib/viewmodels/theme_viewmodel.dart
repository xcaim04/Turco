import 'package:flutter/material.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void cambiar(ThemeMode m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
  }
}

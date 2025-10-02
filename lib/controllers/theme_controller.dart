import 'package:flutter/material.dart';
import '../services/theme_prefs.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode;
  ThemeController(this._mode);

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    await ThemePrefs.save(m);
  }

  Future<void> toggleDark(bool isDark) => setMode(isDark ? ThemeMode.dark : ThemeMode.light);
}

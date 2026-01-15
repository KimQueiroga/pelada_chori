import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePrefs {
  static const _key = 'theme_mode'; // values: 'light' | 'dark' | 'system'

  static Future<void> save(ThemeMode mode) async {
    final sp = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await sp.setString(_key, v);
  }

  static Future<ThemeMode> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system, // default: segue o dispositivo
    };
  }
}

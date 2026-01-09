// frontend/lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  // Load theme từ SharedPreferences
  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(THEME_KEY) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  // Chuyển đổi theme và lưu vào SharedPreferences
  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, _themeMode == ThemeMode.dark);
    notifyListeners();
  }
  
  // Set theme cụ thể
  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, mode == ThemeMode.dark);
    notifyListeners();
  }
}
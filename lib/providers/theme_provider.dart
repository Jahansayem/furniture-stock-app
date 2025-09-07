import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

enum AppThemeMode {
  orange,
  blue,
  dark,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefsKey = 'selected_theme';
  AppThemeMode _currentTheme = AppThemeMode.blue; // Default to blue theme
  
  AppThemeMode get currentTheme => _currentTheme;
  
  ThemeData get themeData {
    switch (_currentTheme) {
      case AppThemeMode.orange:
        return AppTheme.lightTheme;
      case AppThemeMode.blue:
        return AppTheme.blueTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
    }
  }
  
  String get themeName {
    switch (_currentTheme) {
      case AppThemeMode.orange:
        return 'Orange (Shopee)';
      case AppThemeMode.blue:
        return 'Professional Blue';
      case AppThemeMode.dark:
        return 'Dark Mode';
    }
  }
  
  Color get primaryColor {
    switch (_currentTheme) {
      case AppThemeMode.orange:
        return AppTheme.primaryOrange;
      case AppThemeMode.blue:
        return AppTheme.primaryBlue;
      case AppThemeMode.dark:
        return AppTheme.primaryOrange; // Dark theme uses orange accent
    }
  }
  
  /// Initialize theme provider and load saved preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefsKey);
      
      if (savedTheme != null) {
        _currentTheme = AppThemeMode.values.firstWhere(
          (theme) => theme.toString() == savedTheme,
          orElse: () => AppThemeMode.blue, // Default fallback
        );
        notifyListeners();
      }
    } catch (e) {
      // If preferences fail, use default theme
      _currentTheme = AppThemeMode.blue;
    }
  }
  
  /// Change theme and persist to preferences
  Future<void> setTheme(AppThemeMode theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefsKey, theme.toString());
    } catch (e) {
      // Preferences save failed, but theme is still changed
      debugPrint('Failed to save theme preference: $e');
    }
  }
  
  /// Toggle between blue and orange themes (most common use case)
  Future<void> togglePrimaryTheme() async {
    final newTheme = _currentTheme == AppThemeMode.blue 
        ? AppThemeMode.orange 
        : AppThemeMode.blue;
    await setTheme(newTheme);
  }
  
  /// Get theme-appropriate action colors
  Color get addToCartColor {
    switch (_currentTheme) {
      case AppThemeMode.blue:
        return AppColors.addToCartBlue;
      case AppThemeMode.orange:
      case AppThemeMode.dark:
        return AppColors.addToCart;
    }
  }
  
  Color get buyNowColor {
    switch (_currentTheme) {
      case AppThemeMode.blue:
        return AppColors.buyNowBlue;
      case AppThemeMode.orange:
      case AppThemeMode.dark:
        return AppColors.buyNow;
    }
  }
  
  Color get favoriteColor {
    switch (_currentTheme) {
      case AppThemeMode.blue:
        return AppColors.favoriteBlue;
      case AppThemeMode.orange:
      case AppThemeMode.dark:
        return AppColors.favorite;
    }
  }
  
  /// Check if current theme is dark
  bool get isDarkTheme => _currentTheme == AppThemeMode.dark;
  
  /// Check if current theme is blue
  bool get isBlueTheme => _currentTheme == AppThemeMode.blue;
  
  /// Check if current theme is orange
  bool get isOrangeTheme => _currentTheme == AppThemeMode.orange;
}
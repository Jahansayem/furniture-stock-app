import 'package:flutter/material.dart';
import 'app_theme.dart';

// Color Migration Guide from Blue Theme to Shopee eCommerce Theme
// 
// This file helps migrate from the old blue theme to the new Shopee-inspired theme
// Replace the following color references in your screens:

/*
OLD COLOR NAME          →  NEW COLOR NAME
====================================
AppTheme.primaryBlue    →  AppTheme.primaryOrange
AppTheme.lightBlue      →  AppTheme.secondaryOrange  
AppTheme.darkBlue       →  AppTheme.darkOrange
AppTheme.accentBlue     →  AppTheme.accentRed
AppTheme.backgroundBlue →  AppTheme.backgroundGrey
AppTheme.surfaceBlue    →  AppTheme.surfaceGrey

FIND & REPLACE PATTERNS:
========================
1. Find: AppTheme.primaryBlue
   Replace: AppTheme.primaryOrange

2. Find: AppTheme.lightBlue
   Replace: AppTheme.secondaryOrange

3. Find: AppTheme.darkBlue
   Replace: AppTheme.darkOrange

4. Find: AppTheme.accentBlue
   Replace: AppTheme.accentRed

5. Find: AppTheme.backgroundBlue
   Replace: AppTheme.backgroundGrey

6. Find: AppTheme.surfaceBlue
   Replace: AppTheme.surfaceGrey

AFFECTED FILES:
===============
- lib/screens/auth/login_screen.dart
- lib/screens/auth/register_screen.dart
- lib/screens/home/home_screen.dart
- lib/screens/notifications/notification_screen.dart
- lib/screens/stock/stock_overview_screen.dart
- And other screen files that reference the old colors

ADDITIONAL THEMING:
==================
- Use AppColors.discountPrice for sale prices
- Use AppColors.originalPrice for crossed-out prices
- Use AppColors.starRating for ratings
- Use AppTextStyles.productTitle, productPrice etc. for consistent typography
*/

// Helper class to access the new color palette
class ColorMigrationHelper {
  // Primary colors
  static const primaryColor = Color(0xFFEE4D2D);      // Replaces primaryBlue
  static const secondaryColor = Color(0xFFF05339);    // Replaces lightBlue
  static const accentColor = Color(0xFFFF424F);       // Replaces accentBlue
  
  // Background colors
  static const backgroundColor = Color(0xFFF8F8F8);   // Replaces backgroundBlue
  static const surfaceColor = Color(0xFFFAFAFA);      // Replaces surfaceBlue
  
  // Dark colors
  static const darkPrimary = Color(0xFFD73527);       // Replaces darkBlue
}
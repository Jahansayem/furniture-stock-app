import 'package:flutter/material.dart';

class AppTheme {
  // Shopee eCommerce color palette - inspired by Figma design
  static const Color primaryOrange = Color(0xFFEE4D2D);
  static const Color secondaryOrange = Color(0xFFF05339);
  static const Color lightOrange = Color(0xFFFFEDEA);
  static const Color darkOrange = Color(0xFFD73527);
  static const Color accentRed = Color(0xFFFF424F);
  
  // Modern Professional Blue Theme color palette - Figma inspired
  static const Color primaryBlue = Color(0xFF2563EB);  // Modern blue-600
  static const Color secondaryBlue = Color(0xFF3B82F6); // Blue-500
  static const Color lightBlue = Color(0xFFEFF6FF);     // Blue-50
  static const Color darkBlue = Color(0xFF1E40AF);      // Blue-700
  static const Color accentBlue = Color(0xFF0EA5E9);    // Sky-500
  static const Color gradientStart = Color(0xFF3B82F6);
  static const Color gradientEnd = Color(0xFF2563EB);
  
  // Neutral colors from Figma
  static const Color backgroundGrey = Color(0xFFF8F8F8);
  static const Color surfaceGrey = Color(0xFFFAFAFA);
  static const Color lightGrey = Color(0xFFD2D2D2);
  static const Color darkGrey = Color(0xFF1F1F1F);
  static const Color mediumGrey = Color(0xFF666666);
  
  // Additional eCommerce colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color cardBorder = Color(0xFFE5E5E5);
  static const Color divider = Color(0xFFEEEEEE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.light,
        primary: primaryOrange,
        secondary: accentRed,
        surface: backgroundGrey,
        surfaceContainer: surfaceGrey,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkGrey,
        outline: cardBorder,
      ),
      
      // Primary font family - Tiro Bangla for Bengali support
      fontFamily: 'Tiro Bangla',

      // App Bar Theme - Shopee style
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: white,
          size: 24,
        ),
      ),

      // Bottom Navigation Bar Theme - eCommerce style
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryOrange,
        unselectedItemColor: mediumGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card Theme - eCommerce product card style
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: cardBorder,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Elevated Button Theme - Primary action button (Add to Cart, Buy Now)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme - Secondary actions
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          side: const BorderSide(color: primaryOrange, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme - Tertiary actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // Input Decoration Theme - Search bars and forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryOrange, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: lightGrey,
          fontSize: 14,
        ),
      ),

      // Floating Action Button Theme - Primary action
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Chip Theme - Tags and filters
      chipTheme: ChipThemeData(
        backgroundColor: lightOrange,
        selectedColor: primaryOrange,
        labelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: primaryOrange,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryOrange,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return lightGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange.withValues(alpha: 0.5);
          }
          return lightGrey.withValues(alpha: 0.3);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(white),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryOrange;
          }
          return mediumGrey;
        }),
      ),

      // Text Theme - Poppins font family from Figma
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: mediumGrey,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: white,
        size: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.dark,
        primary: primaryOrange,
        secondary: accentRed,
        surface: const Color(0xFF121212),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: white,
          size: 24,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: primaryOrange,
        unselectedItemColor: lightGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2A2A),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: Color(0xFF424242),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static ThemeData get blueTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: backgroundGrey,
        surfaceContainer: surfaceGrey,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkGrey,
        outline: cardBorder,
      ),
      
      // Primary font family - Tiro Bangla for Bengali support
      fontFamily: 'Tiro Bangla',

      // App Bar Theme - Professional Blue style
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: white,
          size: 24,
        ),
      ),

      // Bottom Navigation Bar Theme - Blue style
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mediumGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card Theme - Modern elevated style
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: primaryBlue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Elevated Button Theme - Modern gradient button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 3,
          shadowColor: primaryBlue.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme - Modern outline style
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme - Tertiary actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // Input Decoration Theme - Forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryBlue, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: lightGrey,
          fontSize: 14,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Chip Theme - Professional blue
      chipTheme: ChipThemeData(
        backgroundColor: lightBlue,
        selectedColor: primaryBlue,
        labelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Tiro Bangla',
          color: white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return lightGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue.withValues(alpha: 0.5);
          }
          return lightGrey.withValues(alpha: 0.3);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(white),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return mediumGrey;
        }),
      ),

      // Text Theme - Same as light theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: darkGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Tiro Bangla',
          color: mediumGrey,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: mediumGrey,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: white,
        size: 24,
      ),
    );
  }
}

// Custom colors for eCommerce use cases
class AppColors {
  // Status colors - eCommerce themed
  static const Color success = Color(0xFF00A859);  // Green for success actions
  static const Color warning = Color(0xFFFF8C00);  // Orange for warnings
  static const Color error = Color(0xFFFF424F);    // Red for errors (matching accentRed)
  static const Color info = Color(0xFF1E88E5);     // Blue for information
  
  // Stock status colors
  static const Color lowStock = Color(0xFFFF6B35);     // Orange-red for low stock
  static const Color normalStock = Color(0xFF00A859);  // Green for normal stock
  static const Color outOfStock = Color(0xFFFF424F);   // Red for out of stock
  
  // Price and discount colors
  static const Color originalPrice = Color(0xFF999999); // Grey for crossed-out prices
  static const Color discountPrice = Color(0xFFEE4D2D); // Primary orange for sale prices
  static const Color discountBadge = Color(0xFFFF424F);  // Red for discount badges
  
  // Rating and review colors
  static const Color starRating = Color(0xFFFFD700);    // Gold for star ratings
  static const Color reviewCount = Color(0xFF666666);   // Medium grey for review counts
  
  // Inventory movement colors (keeping for furniture app context)
  static const Color production = Color(0xFF1E88E5);    // Blue for production
  static const Color transfer = Color(0xFF9C27B0);      // Purple for transfers
  static const Color adjustment = Color(0xFFFF8C00);    // Orange for adjustments
  static const Color sale = Color(0xFF00A859);          // Green for sales
  
  // eCommerce specific colors
  static const Color addToCart = Color(0xFFEE4D2D);     // Primary orange
  static const Color buyNow = Color(0xFFFF424F);        // Accent red for urgent action
  static const Color favorite = Color(0xFFFF424F);      // Red for favorites/wishlist
  static const Color categoryBg = Color(0xFFFAFAFA);    // Light grey for category backgrounds
  
  // Blue theme specific colors
  static const Color addToCartBlue = Color(0xFF1565C0);     // Primary blue
  static const Color buyNowBlue = Color(0xFF03DAC6);        // Accent teal for action
  static const Color favoriteBlue = Color(0xFF2196F3);      // Light blue for favorites
  static const Color trustBadge = Color(0xFF1565C0);        // Professional trust indicator
}

// Typography helpers based on Figma design
class AppTextStyles {
  // Product card text styles
  static const TextStyle productTitle = TextStyle(
    fontFamily: 'Tiro Bangla',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.darkGrey,
  );
  
  static const TextStyle productPrice = TextStyle(
    fontFamily: 'Tiro Bangla',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryOrange,
  );
  
  static const TextStyle originalPrice = TextStyle(
    fontFamily: 'Tiro Bangla',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.originalPrice,
    decoration: TextDecoration.lineThrough,
  );
  
  // Button text styles
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: 'Tiro Bangla',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.white,
  );
  
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: 'Tiro Bangla',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.primaryOrange,
  );
  
  // Category and filter text
  static const TextStyle categoryLabel = TextStyle(
    fontFamily: 'Tiro Bangla',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.mediumGrey,
  );
}

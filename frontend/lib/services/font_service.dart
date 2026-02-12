import 'package:flutter/material.dart';

/// Service to handle dynamic font selection based on language
class FontService {
  /// Gets the appropriate font family for the given language code
  static String getFontFamily(String languageCode) {
    switch (languageCode) {
      case 'hi': // Hindi - Devanagari script
        return 'NotoSansDevanagari';
      case 'ta': // Tamil script
        return 'NotoSansTamil';
      case 'te': // Telugu script
        return 'NotoSansTelugu';
      case 'kn': // Kannada script
        return 'NotoSansKannada';
      case 'ml': // Malayalam script
        return 'NotoSansMalayalam';
      case 'en':
      default:
        return 'NotoSans';
    }
  }

  /// Gets font family fallbacks for comprehensive script support
  static List<String> getFontFallbacks(String languageCode) {
    final primary = getFontFamily(languageCode);
    return [
      primary,
      'NotoSans', // Latin fallback
      'NotoSansDevanagari', // Devanagari fallback
      'NotoSansTamil', // Tamil fallback
      'NotoSansTelugu', // Telugu fallback
      'NotoSansKannada', // Kannada fallback
      'NotoSansMalayalam', // Malayalam fallback
    ];
  }

  /// Creates a TextStyle with proper font family for the given language
  static TextStyle createTextStyle(
    String languageCode, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: getFontFamily(languageCode),
      fontFamilyFallback: getFontFallbacks(languageCode).skip(1).toList(),
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Creates a ThemeData with proper fonts for the given language
  static TextTheme createTextTheme(String languageCode, ColorScheme colorScheme) {
    final fontFamily = getFontFamily(languageCode);
    final fallbacks = getFontFallbacks(languageCode).skip(1).toList();

    return TextTheme(
      // Display styles - for large text like headers
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),

      // Headline styles - for section headers
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),

      // Title styles - for card titles, dialog titles
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),

      // Body styles - for regular content text
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
      ),

      // Label styles - for buttons, chips, tabs
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
    );
  }
}
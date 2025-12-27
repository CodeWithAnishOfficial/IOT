import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (from Admin Web)
  static const Color primaryColor = Color(0xFF4680FF);
  static const Color primaryDark = Color(0xFF2F63FF); // 900 equivalent approx
  static const Color secondaryColor = Color(0xFF5B6B79);
  static const Color successColor = Color(0xFF2CA87F);
  
  static const Color scaffoldLight = Color(0xFFF8F9FA); 
  static const Color scaffoldDark = Color(0xFF131920); 

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    primaryColor: primaryColor,
    primaryColorDark: primaryDark,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      background: scaffoldLight,
      error: const Color(0xFFDC2626),
    ),
    scaffoldBackgroundColor: scaffoldLight,
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      bodyLarge: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.black54), // adjusted size
    ),
    extensions: <ThemeExtension<dynamic>>[
      ShimmerColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
      ),
    ],
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0, // flatter design
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    dividerColor: Colors.grey[200],
    iconTheme: const IconThemeData(color: Colors.black54),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    primaryColor: primaryColor,
    primaryColorDark: primaryDark,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: const Color(0xFF1E2A38), // slightly lighter than background
      background: scaffoldDark,
      error: const Color(0xFFE76767),
    ),
    scaffoldBackgroundColor: scaffoldDark,
    appBarTheme: const AppBarTheme(
      color: Color(0xFF1E2A38),
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
      bodyLarge: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
    ),
    extensions: <ThemeExtension<dynamic>>[
      ShimmerColors(
        baseColor: const Color(0xFF1E2A38),
        highlightColor: const Color(0xFF2C3E50),
      ),
    ],
    cardTheme: CardThemeData(
      color: const Color(0xFF1E2A38),
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    dividerColor: Colors.white.withOpacity(0.1),
    iconTheme: const IconThemeData(color: Colors.white70),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E2A38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// Custom shimmer colors extension
class ShimmerColors extends ThemeExtension<ShimmerColors> {
  final Color baseColor;
  final Color highlightColor;

  const ShimmerColors({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  ThemeExtension<ShimmerColors> copyWith({
    Color? baseColor,
    Color? highlightColor,
  }) {
    return ShimmerColors(
      baseColor: baseColor ?? this.baseColor,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }

  @override
  ThemeExtension<ShimmerColors> lerp(
      ThemeExtension<ShimmerColors>? other, double t) {
    if (other is! ShimmerColors) {
      return this;
    }
    return ShimmerColors(
      baseColor: Color.lerp(baseColor, other.baseColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
    );
  }
}

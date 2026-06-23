import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // static const String baseUrl = 'http://societyappapi-abfrh7bqeeb0cyeb.canadacentral-01.azurewebsites.net/api';
   static const String baseUrl = 'https://localhost:51019/api';
  //static const String baseUrl = 'http://societyapp1.runasp.net/api';

  static const String tokenKey = 'auth_token';
  static const String roleKey = 'auth_role';
  static const String userIdKey = 'auth_user_id';
  static const String userNameKey = 'auth_user_name';
}

class AppTheme {
  // ── Modern Fintech Palette ──
  static const Color primary = Color(0xFF064E3B); // Midnight Teal
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color accent = Color(0xFF10B981); // Vibrant Emerald
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textGrey = Color(0xFF64748B); // Slate 500
  static const Color bgGrey = Color(0xFFF8FAFC); // Slate Pearl (Calm off-white)
  static const Color white = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color cardShadow = Color(0xFF0F172A);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: bgGrey,
        appBarTheme: AppBarTheme(
          backgroundColor: white,
          foregroundColor: textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.outfit(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 8,
          shadowColor: cardShadow.withOpacity(0.06),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none, // Remove harsh borders for floating look
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: error),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: primary.withOpacity(0.4),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      );
}

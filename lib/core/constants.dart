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
  // ── Modern Dark Fintech Palette ──
  static const Color primary = Color(0xFF7C3AED); // Vibrant Violet / Purple
  static const Color primaryLight = Color(0xFF261D45); // Dark Violet subtle container
  static const Color accent = Color(0xFF10B981); // Vibrant Emerald
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  
  static const Color textDark = Color(0xFFFFFFFF); // White text
  static const Color textGrey = Color(0xFF9094B6); // Slate/indigo grey
  static const Color bgGrey = Color(0xFF0C0E1A); // Scaffold Background (Deep Navy)
  static const Color white = Color(0xFF181B2F); // Container/Card Background (Dark Slate)
  static const Color divider = Color(0xFF282C4A); // Card Border / Divider color
  static const Color cardShadow = Color(0xFF000000);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: primary,
          onPrimary: Colors.white,
          surface: white,
          background: bgGrey,
          error: error,
        ),
        scaffoldBackgroundColor: bgGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgGrey,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 4,
          shadowColor: cardShadow.withValues(alpha: 0.4),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: divider),
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
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: primary.withValues(alpha: 0.4),
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

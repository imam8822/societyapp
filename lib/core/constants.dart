import 'package:flutter/material.dart';

class AppConstants {
  // ── Change this to your actual server IP/domain ──
  static const String baseUrl = 'http://societyapp1.runasp.net/api';
  static const String tokenKey = 'auth_token';
  static const String roleKey = 'auth_role';
  static const String userIdKey = 'auth_user_id';
  static const String userNameKey = 'auth_user_name';
}

class AppTheme {
  static const Color primary = Color(0xFF1E6B4A);      // deep green
  static const Color primaryLight = Color(0xFFE8F5EE);
  static const Color accent = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color bgGrey = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x0F000000);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: bgGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: white,
          foregroundColor: textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            textStyle: const TextStyle(
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

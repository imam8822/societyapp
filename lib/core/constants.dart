import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  //static const String baseUrl = 'https://localhost:51019/api';
  static const String baseUrl = 'https://societyweb.runasp.net/api';

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String roleKey = 'auth_role';
  static const String userIdKey = 'auth_user_id';

  static const String userNameKey = 'auth_user_name';
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color error;
  final Color warning;
  final Color textDark;
  final Color textGrey;
  final Color bgGrey;
  final Color surfaceWhite;
  final Color divider;
  final Color cardShadow;

  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.error,
    required this.warning,
    required this.textDark,
    required this.textGrey,
    required this.bgGrey,
    required this.surfaceWhite,
    required this.divider,
    required this.cardShadow,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? primaryLight,
    Color? accent,
    Color? error,
    Color? warning,
    Color? textDark,
    Color? textGrey,
    Color? bgGrey,
    Color? surfaceWhite,
    Color? divider,
    Color? cardShadow,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      textDark: textDark ?? this.textDark,
      textGrey: textGrey ?? this.textGrey,
      bgGrey: bgGrey ?? this.bgGrey,
      surfaceWhite: surfaceWhite ?? this.surfaceWhite,
      divider: divider ?? this.divider,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textGrey: Color.lerp(textGrey, other.textGrey, t)!,
      bgGrey: Color.lerp(bgGrey, other.bgGrey, t)!,
      surfaceWhite: Color.lerp(surfaceWhite, other.surfaceWhite, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }

  static const AppColorsExtension light = AppColorsExtension(
    primary: Color(0xFF7C3AED), // Vibrant Violet
    primaryLight: Color(0xFFF3E8FF), // Light Violet container
    accent: Color(0xFF10B981), // Emerald
    error: Color(0xFFEF4444), // Red
    warning: Color(0xFFF59E0B), // Amber
    textDark: Color(0xFF1E293B), // Slate 800
    textGrey: Color(0xFF64748B), // Slate 500
    bgGrey: Color(0xFFF8FAFC), // Slate 50 (Scaffold BG)
    surfaceWhite: Color(0xFFFFFFFF), // White (Card/Container)
    divider: Color(0xFFE2E8F0), // Slate 200
    cardShadow: Color(0xFF94A3B8), // Slate 400 shadow
  );

  static const AppColorsExtension dark = AppColorsExtension(
    primary: Color(0xFF7C3AED), // Vibrant Violet
    primaryLight: Color(0xFF261D45), // Dark Violet subtle container
    accent: Color(0xFF10B981),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    textDark: Color(0xFFFFFFFF), // White text
    textGrey: Color(0xFF9094B6),
    bgGrey: Color(0xFF0C0E1A), // Deep Navy
    surfaceWhite: Color(0xFF181B2F), // Dark Slate
    divider: Color(0xFF282C4A),
    cardShadow: Color(0xFF000000),
  );
}

extension ThemeContext on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}

class AppTheme {
  // Legacy statics mapped to dark palette for backward compatibility during refactor
  static Color primary = const Color(0xFF7C3AED);
  static Color primaryLight = const Color(0xFF261D45);
  static Color accent = const Color(0xFF10B981);
  static Color error = const Color(0xFFEF4444);
  static Color warning = const Color(0xFFF59E0B);
  static Color textDark = const Color(0xFFFFFFFF);
  static Color textGrey = const Color(0xFF9094B6);
  static Color bgGrey = const Color(0xFF0C0E1A);
  static Color white = const Color(0xFF181B2F);
  static Color divider = const Color(0xFF282C4A);
  static Color cardShadow = const Color(0xFF000000);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        extensions: const [AppColorsExtension.light],
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: AppColorsExtension.light.textDark,
          displayColor: AppColorsExtension.light.textDark,
        ),
        colorScheme: ColorScheme.light(
          primary: AppColorsExtension.light.primary,
          onPrimary: Colors.white,
          surface: AppColorsExtension.light.surfaceWhite,
          error: AppColorsExtension.light.error,
        ),
        scaffoldBackgroundColor: AppColorsExtension.light.bgGrey,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsExtension.light.bgGrey,
          foregroundColor: AppColorsExtension.light.textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColorsExtension.light.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AppColorsExtension.light.textDark),
        ),
        cardTheme: CardThemeData(
          color: AppColorsExtension.light.surfaceWhite,
          elevation: 2,
          shadowColor: AppColorsExtension.light.cardShadow.withValues(alpha: 0.2),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColorsExtension.light.divider),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColorsExtension.light.surfaceWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorsExtension.light.surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.light.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.light.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.light.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.light.error),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsExtension.light.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorsExtension.light.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );

  static ThemeData get theme => ThemeData( // dark theme
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: const [AppColorsExtension.dark],
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: AppColorsExtension.dark.textDark,
          displayColor: AppColorsExtension.dark.textDark,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppColorsExtension.dark.primary,
          onPrimary: Colors.white,
          surface: AppColorsExtension.dark.surfaceWhite,
          error: AppColorsExtension.dark.error,
        ),
        scaffoldBackgroundColor: AppColorsExtension.dark.bgGrey,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsExtension.dark.bgGrey,
          foregroundColor: AppColorsExtension.dark.textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColorsExtension.dark.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AppColorsExtension.dark.textDark),
        ),
        cardTheme: CardThemeData(
          color: AppColorsExtension.dark.surfaceWhite,
          elevation: 4,
          shadowColor: AppColorsExtension.dark.cardShadow.withValues(alpha: 0.4),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColorsExtension.dark.divider),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColorsExtension.dark.surfaceWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorsExtension.dark.surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.dark.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.dark.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.dark.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColorsExtension.dark.error),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsExtension.dark.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorsExtension.dark.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
}

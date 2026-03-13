import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color background = black;
  static const Color surfacePrimary = Color(0xFF17191C);
  static const Color surfaceSecondary = Color(0xFF030712);

  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x99FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);
  static const Color textFaint = Color(0x0DFFFFFF);

  static const Color iconDefault = Color(0xFF6B7280);
  static const Color strokeSubtle = Color(0x1AFFFFFF);
  static const Color strokeSoft = Color(0x0DFFFFFF);

  static const Color blue = Color(0xFF51A2FF);
  static const Color blueSoft = Color(0x332B7FFF);
  static const Color purple = Color(0xFFC27AFF);
  static const Color purpleStrong = Color(0xFFAD46FF);
  static const Color green = Color(0xFF05DF72);
  static const Color greenStrong = Color(0xFF00C950);
  static const Color orange = Color(0xFFFF8904);
  static const Color orangeStrong = Color(0xFFFF6900);
  static const Color red = Color(0xFFEF4444);
  static const Color redStrong = Color(0xFFFB2C36);
  static const Color pink = Color(0xFFDC269C);
  static const Color coral = Color(0x26FF6467);

  static const Color cardOverlayStrong = Color(0xCC17191C);
  static const Color cardOverlaySoft = Color(0x9917191C);
  static const Color navOverlay = Color(0x6617191C);
}


class AppGradients {
  AppGradients._();

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.surfaceSecondary,
      AppColors.surfacePrimary,
      AppColors.black,
    ],
  );

  static const LinearGradient cardSurface = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      AppColors.cardOverlayStrong,
      AppColors.cardOverlaySoft,
    ],
  );

  static const LinearGradient accentPink = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.red,
      AppColors.pink,
    ],
  );

  static const LinearGradient accentWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0x33FF6900),
      Color(0x33FB2C36),
      Color(0xB3FF8904),
    ],
  );

  static const LinearGradient strokeFade = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      Color(0x0FFFFFFF),
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
  );
}


class AppRadii {
  AppRadii._();

  static const double screen = 40;
  static const double card = 40;
  static const double quickAction = 28;
  static const double iconContainer = 20;
  static const double fab = 999;
}


class AppShadows {
  AppShadows._();

  static const List<BoxShadow> fabGlow = <BoxShadow>[
    BoxShadow(
      color: Color(0x66EF4444),
      blurRadius: 30,
      spreadRadius: 2,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x66DC269C),
      blurRadius: 48,
      spreadRadius: 0,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
  ];
}


class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blue,
      onPrimary: AppColors.white,
      secondary: AppColors.pink,
      onSecondary: AppColors.white,
      error: AppColors.redStrong,
      onError: AppColors.white,
      surface: AppColors.surfacePrimary,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.surfaceSecondary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.strokeSubtle,
      outlineVariant: AppColors.strokeSoft,
      shadow: AppColors.black,
      scrim: AppColors.black,
      inverseSurface: AppColors.white,
      onInverseSurface: AppColors.black,
      inversePrimary: AppColors.blueSoft,
    );

    const TextTheme textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.2,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.2,
        letterSpacing: 0.8,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      canvasColor: AppColors.background,
      dividerColor: AppColors.strokeSoft,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfacePrimary,
        shadowColor: AppColors.black,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.strokeSoft),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.iconDefault,
        selectedIconTheme: IconThemeData(color: AppColors.textPrimary),
        unselectedIconTheme: IconThemeData(color: AppColors.iconDefault),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: AppColors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconDefault,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.iconDefault,
        textColor: AppColors.textPrimary,
      ),
    );
  }
}
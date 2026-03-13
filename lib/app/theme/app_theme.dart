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
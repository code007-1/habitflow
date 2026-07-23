import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Light Palette (Primary theme)
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Very light slate blue/white background
  static const Color surface = Color(
    0xFFFFFFFF,
  ); // Pure white card/surface background
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Light elevated grey

  // main colors
  static const Color primary = Color(0xFF1FD5F9); // Modern Indigo
  static const Color secondary = Color(0xFF36E2C6); // Modern Indigo
  static const Color color3 = Color(0xFF30E830); // Modern Indigo
  static const Color color4 = Color(0xFFF58A3D); // Modern Indigo
  static const Color color5 = Color(0xFF9167E4); // Modern Indigo

  // Brand tints & accents (derived from primary → secondary)
  static const Color primarySoft = Color(0xFFE4FAFE); // Very light cyan tint
  static const Color primaryDeep = Color(0xFF0EA5C4); // Deeper cyan for text/CTA
  static const Color secondaryDeep = Color(0xFF0FB89C); // Deeper teal accent

  // semantic colors
  static const Color error = Color(0xFFDD3C57); // Error
  static const Color warning = Color(0xFFF5B83D); // Warning
  static const Color success = Color(0xFF22C358); // Success
  static const Color info = Color(0xFF467EE3); // Info

  // Streak / reward colors
  static const Color gold = Color(0xFFFFBB00); // Gold for streaks / achievements
  static const Color goldLight = Color(0xFFFFF3CC); // Light gold background
  static const Color streak = Color(0xFFFF6B35); // Warm orange for fire streak
  static const Color streakLight = Color(0xFFFFEDE6); // Light streak background

  // gray color set
  static const Color grey1 = Color(0xFFF8FAFC);
  static const Color grey2 = Color(0xFFF1F5F9);
  static const Color grey3 = Color(0xFFE2E8F0);
  static const Color grey4 = Color(0xFFcbd5e1);
  static const Color grey5 = Color(0xff64748b);
  static const Color grey6 = Color(0xff475569);
  static const Color grey7 = Color(0xff0f172a);
  static const Color grey8 = Color(0xff000000);

  // Elevation shadow tints
  static const Color shadowSoft = Color(0x14000000); // ~8% black, soft cards
  static const Color shadowBrand = Color(0x331FD5F9); // brand-tinted glow

  // Cohesive brand gradient (matches primary → secondary)
  static const Gradient brandGradient = LinearGradient(
    colors: [Color(0xFF1FD5F9), Color(0xFF36E2C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Richer hero gradient for headline cards
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF0EA5C4), Color(0xFF1FD5F9), Color(0xFF36E2C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warm streak gradient for fire / achievement accents
  static const Gradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Beautiful Premium Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color.fromARGB(255, 12, 14, 17)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient incomeGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient expenseGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

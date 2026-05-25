import 'package:flutter/material.dart';

class AppColors {
  // Paleta verde (igual que el esqueleto HTML)
  static const Color verdeOscuro = Color(0xFF1A3D2B);
  static const Color verde = Color(0xFF2D6A4F);
  static const Color verdeMedio = Color(0xFF40916C);
  static const Color verdeClaro = Color(0xFF52B788);
  static const Color menta = Color(0xFF95D5B2);
  static const Color niebla = Color(0xFFD8F3DC);
  static const Color crema = Color(0xFFF8F4E8);

  // Tierra y acento
  static const Color tierra = Color(0xFF8B5E3C);
  static const Color tierraClaro = Color(0xFFC4956A);
  static const Color acento = Color(0xFFE9C46A);

  // Riesgo
  static const Color riskHigh = Color(0xFFC1440E);
  static const Color riskMedium = Color(0xFFD97706);
  static const Color riskLow = Color(0xFF40916C);

  // Util
  static const Color azul = Color(0xFF457B9D);
  static const Color gris = Color(0xFF6B7C70);
  static const Color blanco = Color(0xFFFFFFFF);

  // Aliases para BloC/widgets
  static const Color primary = verde;
  static const Color primaryLight = verdeMedio;
  static const Color bgSidebar = verdeOscuro;
  static const Color surface = blanco;
  static const Color background = crema;

  // ColorScheme Material 3 — tema claro (crema + verde)
  static ColorScheme get colorScheme => ColorScheme(
        brightness: Brightness.light,
        primary: verde,
        onPrimary: blanco,
        primaryContainer: niebla,
        onPrimaryContainer: verdeOscuro,
        secondary: verdeMedio,
        onSecondary: blanco,
        secondaryContainer: menta,
        onSecondaryContainer: verdeOscuro,
        tertiary: acento,
        onTertiary: verdeOscuro,
        tertiaryContainer: const Color(0xFFFEF3C7),
        onTertiaryContainer: const Color(0xFF92400E),
        error: riskHigh,
        onError: blanco,
        errorContainer: const Color(0xFFFCE8E0),
        onErrorContainer: riskHigh,
        surface: blanco,
        onSurface: verdeOscuro,
        surfaceContainerHighest: niebla,
        onSurfaceVariant: gris,
        outline: const Color(0xFFDDE8E0),
        shadow: verdeOscuro,
        inverseSurface: verdeOscuro,
        onInverseSurface: crema,
        inversePrimary: menta,
      );
}

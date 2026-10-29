import 'package:flutter/material.dart';

/// 全局配色。浅色/暗色各一套，页面里只认这里的名字。
class Palette {
  final Color bg;
  final Color card;
  final Color ink;
  final Color muted;
  final Color hint;
  final Color divider;
  final Color chipBg;
  final Color primary;
  final Color success;
  final Color danger;

  const Palette({
    required this.bg,
    required this.card,
    required this.ink,
    required this.muted,
    required this.hint,
    required this.divider,
    required this.chipBg,
    required this.primary,
    required this.success,
    required this.danger,
  });

  static const light = Palette(
    bg: Color(0xFFF6F5F1),
    card: Colors.white,
    ink: Color(0xFF1C1B18),
    muted: Color(0xFF6B6A63),
    hint: Color(0xFF9A988F),
    divider: Color(0xFFEDEBE4),
    chipBg: Color(0xFFF1EFE9),
    primary: Color(0xFF2E7D6F),
    success: Color(0xFF2E7D4F),
    danger: Color(0xFFC2453E),
  );

  static const dark = Palette(
    bg: Color(0xFF121417),
    card: Color(0xFF1C1F24),
    ink: Color(0xFFEDEAE3),
    muted: Color(0xFFA8A59D),
    hint: Color(0xFF7C7970),
    divider: Color(0xFF2A2E34),
    chipBg: Color(0xFF252930),
    primary: Color(0xFF63C4B2),
    success: Color(0xFF6FC48F),
    danger: Color(0xFFE38078),
  );
}

extension PaletteContext on BuildContext {
  Palette get pal =>
      Theme.of(this).brightness == Brightness.dark ? Palette.dark : Palette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

ThemeData buildTheme(Palette p, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.ink,
      ),
      iconTheme: IconThemeData(color: p.ink),
    ),
    cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: p.card),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: TextStyle(color: p.bg, fontSize: 13),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.card),
    dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
  );
}

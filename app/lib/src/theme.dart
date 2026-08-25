import 'package:flutter/material.dart';

/// Visual language shared with the project's assessment materials: high
/// contrast for use in bright classrooms, generous touch targets, and the
/// same teal/ochre/rust semantics used in the architecture diagrams —
/// teal for a pass or a deterministic rule, ochre for anything needing
/// human confirmation, rust for a fail.
abstract final class Palette {
  static const teal = Color(0xFF0F7B75);
  static const tealDark = Color(0xFF0A5A55);
  static const tealWash = Color(0xFFE4F0EE);
  static const ochre = Color(0xFF8F5C0C);
  static const ochreWash = Color(0xFFF7EFDF);
  static const rust = Color(0xFFA0392C);
  static const rustWash = Color(0xFFF8E8E4);
  static const ink = Color(0xFF14181A);
  static const inkMuted = Color(0xFF4A5352);
  static const rule = Color(0xFFDCE2E0);
  static const paper = Color(0xFFFBFCFB);
}

/// Minimum tappable edge. KICD's platform standards require on-screen
/// elements "of sufficient size and responsiveness" on touch devices; 56dp
/// comfortably clears the 48dp floor for a tool used at speed.
const double kTouchTarget = 56;

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.teal,
      primary: Palette.teal,
      surface: Palette.paper,
    ),
    scaffoldBackgroundColor: Palette.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.paper,
      foregroundColor: Palette.ink,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
    dividerTheme: const DividerThemeData(color: Palette.rule, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kTouchTarget),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kTouchTarget),
        side: const BorderSide(color: Palette.rule, width: 1.5),
        foregroundColor: Palette.ink,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Palette.rule),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Palette.rule),
      ),
    ),
  );
}

/// Small uppercase label used for level codes and section headers.
class LevelChip extends StatelessWidget {
  const LevelChip(
    this.text, {
    super.key,
    this.background = Palette.ink,
    this.foreground = Colors.white,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}

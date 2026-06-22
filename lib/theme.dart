import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "Coffee" design language — a warm paper receipt.
///
/// Light, tactile, café. Cream paper, espresso ink, a terracotta call to
/// action, and NEAR mint reserved for the single "settled on-chain" moment.
/// Deliberately the opposite of the dark glass SDK demo so the product has
/// its own identity.
class Coffee {
  Coffee._();

  // ── Paper & ink ──────────────────────────────────────────────────────────
  static const paper = Color(0xFFFBF6EC); // warm cream canvas
  static const paperDeep = Color(0xFFF3E9D6); // card / inset fill
  static const receipt = Color(0xFFFFFDF8); // the printed slip (whiter)
  static const ink = Color(0xFF211B14); // warm near-black text
  static const inkSoft = Color(0xFF7A6B57); // secondary / muted
  static const line = Color(0xFFE4D7C0); // hairline / divider
  static const lineSoft = Color(0xFFEDE3D1);

  // ── Accents ──────────────────────────────────────────────────────────────
  static const terracotta = Color(0xFFDD5E36); // primary CTA / heat
  static const terracottaDeep = Color(0xFFC04A26);
  static const espresso = Color(0xFF5B3A22); // coffee brown
  static const amber = Color(0xFFE7A14B); // warm highlight
  static const mint = Color(0xFF00EC97); // NEAR — the on-chain jewel
  static const mintInk = Color(0xFF064D38); // legible mint text on light

  // ── Radii / spacing ──────────────────────────────────────────────────────
  static const rLg = 24.0;
  static const rMd = 16.0;
  static const rSm = 10.0;

  // ── Type ─────────────────────────────────────────────────────────────────
  // Fraunces (wonky warm serif) for display, DM Sans for UI, Space Mono for
  // the receipt / amounts / hashes.
  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w600,
          Color color = ink,
          double? height,
          double letter = -0.5}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letter,
      );

  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w400,
          Color color = ink,
          double? height,
          double letter = 0}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letter,
      );

  static TextStyle mono(double size,
          {FontWeight weight = FontWeight.w400,
          Color color = ink,
          double letter = 0,
          double? height}) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letter,
        height: height,
      );

  /// A small all-caps "stamped" label (used for receipt headers, eyebrows).
  static TextStyle stamp(double size, {Color color = inkSoft}) => GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 2.5,
      );

  static ThemeData theme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      colorScheme: base.colorScheme.copyWith(
        primary: terracotta,
        secondary: mint,
        surface: paper,
        onSurface: ink,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: terracotta,
        selectionColor: Color(0x33DD5E36),
        selectionHandleColor: terracotta,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

import 'package:flutter/material.dart';

/// Design tokens of the "Onda" redesign (see Rediseño BeatzPro.html).
///
/// The brand gradient lives only in the waveform, the "now playing" bars and
/// loading; everything else is ink on black.
@immutable
class BeatzColors extends ThemeExtension<BeatzColors> {
  const BeatzColors({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.ink,
    required this.muted,
    required this.line,
    required this.dim,
    required this.good,
    required this.warn,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color raised;
  final Color ink;
  final Color muted;
  final Color line;
  final Color dim;
  final Color good;
  final Color warn;
  final bool isDark;

  static const dark = BeatzColors(
    bg: Color(0xFF0C0B10),
    surface: Color(0xFF17151E),
    raised: Color(0xFF201E29),
    ink: Color(0xFFF3F1F7),
    muted: Color(0xFFA5A2B2),
    line: Color(0xFF26232F),
    dim: Color(0x42F3F1F7),
    good: Color(0xFF58D08A),
    warn: Color(0xFFF4B63F),
    isDark: true,
  );

  static const light = BeatzColors(
    bg: Color(0xFFF6F5F9),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    ink: Color(0xFF15131B),
    muted: Color(0xFF5C5967),
    line: Color(0xFFE3E1E8),
    dim: Color(0x3815131B),
    good: Color(0xFF1D8A4B),
    warn: Color(0xFF9A6400),
    isDark: false,
  );

  /// Palette of the dynamic theme: every surface takes the hue of the song
  /// cover, kept dark so the ink text always reads (> 4.5:1).
  factory BeatzColors.tinted(Color base) {
    final hsl = HSLColor.fromColor(base);
    final sat = (hsl.saturation * 0.65).clamp(0.0, 0.55);
    Color at(double lightness, [double satFactor = 1]) => HSLColor.fromAHSL(
            1, hsl.hue, (sat * satFactor).clamp(0.0, 1.0), lightness)
        .toColor();
    return BeatzColors(
      bg: at(0.08),
      surface: at(0.125),
      raised: at(0.165),
      ink: const Color(0xFFF3F1F7),
      muted: at(0.74, 0.45),
      line: at(0.21),
      dim: const Color(0x42F3F1F7),
      good: const Color(0xFF58D08A),
      warn: const Color(0xFFF4B63F),
      isDark: true,
    );
  }

  /// Brand colours: magenta → violet → cyan.
  static const brandMagenta = Color(0xFFD63A9E);
  static const brandViolet = Color(0xFF7456E6);
  static const brandCyan = Color(0xFF34B6F0);
  static const heart = Color(0xFFFF7AB8);

  static const brandGradient = LinearGradient(
    colors: [brandMagenta, brandViolet, brandCyan],
    stops: [0, 0.55, 1],
  );

  @override
  BeatzColors copyWith({
    Color? bg,
    Color? surface,
    Color? raised,
    Color? ink,
    Color? muted,
    Color? line,
    Color? dim,
    Color? good,
    Color? warn,
    bool? isDark,
  }) =>
      BeatzColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        raised: raised ?? this.raised,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        dim: dim ?? this.dim,
        good: good ?? this.good,
        warn: warn ?? this.warn,
        isDark: isDark ?? this.isDark,
      );

  @override
  BeatzColors lerp(ThemeExtension<BeatzColors>? other, double t) {
    if (other is! BeatzColors) return this;
    return BeatzColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      good: Color.lerp(good, other.good, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension BeatzThemeX on BuildContext {
  /// Design colours of the current theme (dark when the theme has none).
  BeatzColors get beatz =>
      Theme.of(this).extension<BeatzColors>() ?? BeatzColors.dark;
}

/// Spacing, radii and type tokens used across the redesigned screens.
class BeatzTokens {
  BeatzTokens._();

  static const radiusCover = 10.0;
  static const radiusCard = 14.0;
  static const radiusBox = 16.0;
  static const radiusPill = 999.0;
  static const pagePadding = 18.0;

  static const fontLyrics = 'Acme';
}

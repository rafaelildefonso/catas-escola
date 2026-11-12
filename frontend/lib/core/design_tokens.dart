import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Semantic visual tokens shared by every CATAS surface.
///
/// Keep brand colors, state colors and elevation decisions here instead of
/// scattering raw values throughout screens and AI response components.
@immutable
class CatasThemeTokens extends ThemeExtension<CatasThemeTokens> {
  final Color canvas;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color borderSubtle;
  final Color borderStrong;
  final Color success;
  final Color warning;
  final Color info;
  final Color danger;
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;

  const CatasThemeTokens({
    required this.canvas,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.borderSubtle,
    required this.borderStrong,
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
  });

  static const light = CatasThemeTokens(
    canvas: Color(0xFFF7F7F8),
    surfaceRaised: Colors.white,
    surfaceMuted: Color(0xFFF1F1F3),
    borderSubtle: Color(0xFFE4E4E7),
    borderStrong: Color(0xFFD4D4D8),
    success: Color(0xFF15803D),
    warning: Color(0xFFA16207),
    info: Color(0xFF126BEB),
    danger: Color(0xFFDC2626),
    radiusSmall: 10,
    radiusMedium: 14,
    radiusLarge: 20,
  );

  static const dark = CatasThemeTokens(
    canvas: Color(0xFF09090B),
    surfaceRaised: Color(0xFF111113),
    surfaceMuted: Color(0xFF1C1C1F),
    borderSubtle: Color(0xFF27272A),
    borderStrong: Color(0xFF3F3F46),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    danger: Color(0xFFF87171),
    radiusSmall: 10,
    radiusMedium: 14,
    radiusLarge: 20,
  );

  @override
  CatasThemeTokens copyWith({
    Color? canvas,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? borderSubtle,
    Color? borderStrong,
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
  }) {
    return CatasThemeTokens(
      canvas: canvas ?? this.canvas,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
    );
  }

  @override
  CatasThemeTokens lerp(CatasThemeTokens? other, double t) {
    if (other is! CatasThemeTokens) return this;
    return CatasThemeTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
    );
  }
}

extension CatasThemeContext on BuildContext {
  CatasThemeTokens get catasTokens =>
      Theme.of(this).extension<CatasThemeTokens>()!;

  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

abstract final class CatasMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 320);
  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
}

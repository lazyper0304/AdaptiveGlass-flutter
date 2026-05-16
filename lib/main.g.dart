part of 'main.dart';

ThemeData _buildTheme(ColorScheme scheme) {
  final isDark = scheme.brightness == Brightness.dark;

  return ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GoTransitions.cupertino,
        TargetPlatform.iOS: GoTransitions.cupertino,
        TargetPlatform.macOS: GoTransitions.cupertino,
      },
    ),
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0E1116)
        : const Color(0xFFF4F7F5),
    fontFamily: 'SmileySans',
    useMaterial3: true,
  );
}

const _glassThemeData = GlassThemeData(
  light: GlassThemeVariant(
    settings: GlassThemeSettings(
      blur: 12,
      thickness: 30,
      glassColor: Color(0x72FFFFFF),
      lightIntensity: 0.86,
      saturation: 1.04,
    ),
    quality: GlassQuality.standard,
    glowColors: GlassGlowColors(
      primary: Color(0x665FBF76),
      secondary: Color(0x6679D6FF),
      info: Color(0x6679D6FF),
      success: Color(0x6634C759),
    ),
  ),
  dark: GlassThemeVariant(
    settings: GlassThemeSettings(
      blur: 12,
      thickness: 34,
      glassColor: Color(0x4A1C2026),
      lightIntensity: 1.25,
      saturation: 1.08,
    ),
    quality: GlassQuality.standard,
    glowColors: GlassGlowColors(
      primary: Color(0x66C7FF12),
      secondary: Color(0x6679D6FF),
      info: Color(0x6679D6FF),
      success: Color(0x6634C759),
    ),
  ),
);

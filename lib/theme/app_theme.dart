import 'package:flutter/material.dart';

/// Brand palette: ivory, dusty rose, rose-gold, deep plum text.
class Brand {
  static const ivory = Color(0xFFFBF6F1);
  static const ivoryDeep = Color(0xFFF3E8DF);
  static const rose = Color(0xFFC97B84);
  static const roseDeep = Color(0xFFA85E6A);
  static const roseGold = Color(0xFFB98A6E);
  static const gold = Color(0xFFD4AF8C);
  static const plum = Color(0xFF3B2530);
  static const plumSoft = Color(0xFF7A6069);

  static const night = Color(0xFF181215);
  static const nightSurface = Color(0xFF241B1F);
  static const nightCard = Color(0xFF2E2328);
  static const roseNight = Color(0xFFE8A6AE);
  static const goldNight = Color(0xFFE2C09F);
  static const textNight = Color(0xFFF5EAE6);

  static const roseGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE7C3A8), Color(0xFFC98F86), Color(0xFFB0707C)],
  );
}

/// Variable fonts need an explicit wght axis value to render the requested weight.
List<FontVariation> wght(double w) => [FontVariation('wght', w)];

class AppTheme {
  static bool _isAr(Locale l) => l.languageCode == 'ar';

  /// Display family: El Messiri (Arabic) / Playfair Display (Latin).
  static String displayFamily(Locale l) => _isAr(l) ? 'ElMessiri' : 'PlayfairDisplay';

  static ThemeData light(Locale locale) => _build(
        locale,
        ColorScheme(
          brightness: Brightness.light,
          primary: Brand.roseDeep,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFF6DDE0),
          onPrimaryContainer: Brand.plum,
          secondary: Brand.roseGold,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFF2E1D3),
          onSecondaryContainer: Brand.plum,
          tertiary: Brand.gold,
          onTertiary: Brand.plum,
          error: const Color(0xFFB3261E),
          onError: Colors.white,
          surface: Brand.ivory,
          onSurface: Brand.plum,
          onSurfaceVariant: Brand.plumSoft,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFFDF9F6),
          surfaceContainer: Brand.ivoryDeep,
          surfaceContainerHigh: const Color(0xFFEFE2D8),
          outline: const Color(0xFFD9C6BC),
          outlineVariant: const Color(0xFFEADBD2),
        ),
      );

  static ThemeData dark(Locale locale) => _build(
        locale,
        ColorScheme(
          brightness: Brightness.dark,
          primary: Brand.roseNight,
          onPrimary: Brand.night,
          primaryContainer: const Color(0xFF5A3540),
          onPrimaryContainer: Brand.textNight,
          secondary: Brand.goldNight,
          onSecondary: Brand.night,
          secondaryContainer: const Color(0xFF4A3A30),
          onSecondaryContainer: Brand.textNight,
          tertiary: Brand.goldNight,
          onTertiary: Brand.night,
          error: const Color(0xFFF2B8B5),
          onError: const Color(0xFF601410),
          surface: Brand.night,
          onSurface: Brand.textNight,
          onSurfaceVariant: const Color(0xFFCDB8BE),
          surfaceContainerLowest: const Color(0xFF120D10),
          surfaceContainerLow: Brand.nightSurface,
          surfaceContainer: Brand.nightCard,
          surfaceContainerHigh: const Color(0xFF382B31),
          outline: const Color(0xFF6B5960),
          outlineVariant: const Color(0xFF45373D),
        ),
      );

  static ThemeData _build(Locale locale, ColorScheme cs) {
    final display = displayFamily(locale);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
    );
    final t = base.textTheme;
    TextStyle d(TextStyle? s, double size, double w) => (s ?? const TextStyle()).copyWith(
          fontFamily: display,
          fontSize: size,
          fontVariations: wght(w),
          height: 1.25,
          color: cs.onSurface,
        );
    return base.copyWith(
      textTheme: t.copyWith(
        displaySmall: d(t.displaySmall, 34, 700),
        headlineMedium: d(t.headlineMedium, 28, 700),
        headlineSmall: d(t.headlineSmall, 23, 600),
        titleLarge: d(t.titleLarge, 20, 600),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
        bodyLarge: t.bodyLarge?.copyWith(fontSize: 16.5, height: 1.65),
        bodyMedium: t.bodyMedium?.copyWith(fontSize: 14.5, height: 1.6),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: cs.onSurface,
        titleTextStyle: d(t.titleLarge, 20, 600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLow,
        indicatorColor: cs.primaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Tajawal', fontSize: 12.5, fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w500, color: cs.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: cs.outline),
          textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: cs.primary, width: 1.6)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1),
    );
  }
}

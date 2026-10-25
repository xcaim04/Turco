import 'package:flutter/material.dart';

const _seed = Color(0xFF00695C);

final ColorScheme esquemaClaro =
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light).copyWith(
  primary: const Color(0xFF006A60),
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: const Color(0xFF9EF2E4),
  onPrimaryContainer: const Color(0xFF00201C),
  secondaryContainer: const Color(0xFFCCE8E2),
  onSecondaryContainer: const Color(0xFF05201C),
  tertiary: const Color(0xFF456179),
  tertiaryContainer: const Color(0xFFCDE5FF),
  onTertiaryContainer: const Color(0xFF001D32),
  error: const Color(0xFFBA1A1A),
  onError: const Color(0xFFFFFFFF),
  errorContainer: const Color(0xFFFFDAD6),
  onErrorContainer: const Color(0xFF410002),
  surface: const Color(0xFFF4FBF9),
  onSurface: const Color(0xFF171D1C),
  onSurfaceVariant: const Color(0xFF3F4947),
  surfaceContainer: const Color(0xFFE9EFED),
  outline: const Color(0xFF6F7977),
  outlineVariant: const Color(0xFFBEC9C6),
);

final ColorScheme esquemaOscuro =
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark).copyWith(
  primary: const Color(0xFF53DBC9),
  onPrimary: const Color(0xFF003731),
  primaryContainer: const Color(0xFF005047),
  onPrimaryContainer: const Color(0xFF9EF2E4),
  secondaryContainer: const Color(0xFF314B47),
  onSecondaryContainer: const Color(0xFFCCE8E2),
  tertiary: const Color(0xFFADCAE6),
  tertiaryContainer: const Color(0xFF2D4960),
  onTertiaryContainer: const Color(0xFFCDE5FF),
  error: const Color(0xFFFFB4AB),
  onError: const Color(0xFF690005),
  errorContainer: const Color(0xFF93000A),
  onErrorContainer: const Color(0xFFFFDAD6),
  surface: const Color(0xFF0E1514),
  onSurface: const Color(0xFFDCE4E2),
  onSurfaceVariant: const Color(0xFFBEC9C6),
  surfaceContainer: const Color(0xFF1A2120),
  outline: const Color(0xFF899390),
  outlineVariant: const Color(0xFF3F4947),
);

TextTheme _textos(ColorScheme cs) {
  final base = Typography.material2021().black.apply(
        fontFamily: 'Poppins',
        bodyColor: cs.onSurface,
        displayColor: cs.onSurface,
      );
  return base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: base.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
    labelSmall: base.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
  );
}

ThemeData construirTema(Brightness brillo) {
  final cs = brillo == Brightness.light ? esquemaClaro : esquemaOscuro;
  final tt = _textos(cs);
  RoundedRectangleBorder forma(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
  OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brillo,
    colorScheme: cs,
    fontFamily: 'Poppins',
    textTheme: tt,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: tt.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: cs.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: forma(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: forma(12),
        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: forma(12),
        side: BorderSide(color: cs.outline),
        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: forma(12),
        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: borde(cs.outline),
      enabledBorder: borde(cs.outline),
      focusedBorder: borde(cs.primary, 2),
      errorBorder: borde(cs.error),
      focusedErrorBorder: borde(cs.error, 2),
      errorStyle: tt.bodyMedium?.copyWith(color: cs.error, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      shape: forma(12),
      side: BorderSide(color: cs.outlineVariant),
      selectedColor: cs.secondaryContainer,
      labelStyle: tt.bodyMedium,
      showCheckmark: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surfaceContainer,
      indicatorColor: cs.secondaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => tt.labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      extendedTextStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      shape: forma(16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: forma(12),
      contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surfaceContainer,
      shape: forma(28),
      titleTextStyle: tt.titleLarge,
      contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: cs.surface,
      modalBackgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cs.surfaceContainer,
      shape: forma(12),
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1, thickness: 1),
  );
}

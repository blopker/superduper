import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF000000);
  static const inkLight = Color(0xFF050505);
  static const surface = Color(0xFF080808);
  static const surfaceRaised = Color(0xFF111111);
  static const border = Color(0xFF2E2931);
  static const magenta = Color(0xFFF327AE);
  static const magentaSoft = Color(0xFFFF78CD);
  static const yellow = Color(0xFFFFD84A);
  static const violet = Color(0xFF8E50FF);
  static const mint = Color(0xFF5EE6A8);
  static const orange = Color(0xFFFFAD5C);
  static const text = Color(0xFFFFF8FF);
  static const textMuted = Color(0xFFCDBFD3);
}

abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.magenta,
      onPrimary: Color(0xFF31001F),
      primaryContainer: Color(0xFF5B113F),
      onPrimaryContainer: Color(0xFFFFD8EB),
      secondary: AppColors.yellow,
      onSecondary: Color(0xFF302800),
      secondaryContainer: Color(0xFF4D4100),
      onSecondaryContainer: Color(0xFFFFEFA3),
      tertiary: AppColors.violet,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF38206E),
      onTertiaryContainer: Color(0xFFEADDFF),
      error: Color(0xFFFF6E78),
      onError: Color(0xFF470008),
      errorContainer: Color(0xFF660611),
      onErrorContainer: Color(0xFFFFDADB),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      surfaceContainerLowest: AppColors.ink,
      surfaceContainerLow: AppColors.inkLight,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceRaised,
      surfaceContainerHighest: Color(0xFF181818),
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.border,
      outlineVariant: Color(0xFF34243D),
    );

    final baseText = Typography.material2021().white.apply(
      fontFamily: 'monospace',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      canvasColor: AppColors.ink,
      splashFactory: InkSparkle.splashFactory,
      textTheme: baseText.copyWith(
        displaySmall: baseText.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          height: 1.02,
        ),
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          height: 1.45,
          color: AppColors.textMuted,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          height: 1.4,
          color: AppColors.textMuted,
        ),
        labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 19,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.magenta, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(132, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(132, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: const BorderSide(color: AppColors.textMuted),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.magentaSoft,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.text,
          minimumSize: const Size.square(44),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF111111),
        contentTextStyle: TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.yellow
              : AppColors.border,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.magenta,
        linearTrackColor: AppColors.surfaceRaised,
      ),
      useMaterial3: true,
    );
  }
}

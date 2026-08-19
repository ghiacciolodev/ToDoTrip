import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'brand.dart';
import 'colors.dart';

/// Shipped in the app, not fetched at runtime.
///
/// It used to come from Google's servers on first launch, which handed every
/// user's IP address to a third party for no functional gain — the exact
/// practice German courts have fined websites over. One variable file covers
/// every weight the app uses; its licence travels beside it in assets/fonts.
const _fontFamily = 'Inter';

/// Application theme.
///
/// One Material 3 theme for both platforms, tuned to avoid the details that
/// make an app read as "Android on iOS": no filled app bar, floating snack
/// bars, sheets instead of dialogs.
///
/// The accent arrives as a [Brand] rather than being read from a constant, so
/// the whole app follows the colour the user picked. Its three roles map onto
/// the scheme slots that already mean the same thing, which is why widgets can
/// ask for `colorScheme.primary` and friends instead of importing a palette:
///
///   * `primary`             — fills
///   * `onPrimaryContainer`  — the readable shade, for text and small icons
///   * `primaryContainer`    — the quiet tint behind a selected row
abstract final class AppTheme {
  /// The colour half of the theme, on its own.
  ///
  /// Separate from [light] so the palette can be asserted on without building
  /// the rest of a theme around it.
  static ColorScheme schemeFor(Brand brand) {
    // fromSeed harmonises the seed into something slightly different, so the
    // brand colours are put back explicitly.
    return ColorScheme.fromSeed(
      seedColor: brand.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand.primary,
      onPrimary: Colors.white,
      primaryContainer: brand.tint,
      onPrimaryContainer: brand.dark,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.terracotta,
    );
  }

  static ThemeData light(Brand brand) {
    final scheme = schemeFor(brand);

    final textTheme = ThemeData.light().textTheme.apply(
      fontFamily: _fontFamily,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,

      // iOS-style horizontal slide on Apple platforms, Android default elsewhere.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(brand.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.terracotta),
        focusedErrorBorder: _inputBorder(AppColors.terracotta, width: 1.6),
      ),

      // Floating with a margin, or it sits under the iPhone home indicator.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // M3 would tint this with a secondaryContainer derived from the seed,
      // which is not the brand colour. Set explicitly, like primary itself.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Styled once here so both navigation bars — the app shell and the trip
      // shell — stay identical without repeating themselves.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: brand.tint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _fontFamily,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? brand.dark
                : AppColors.inkMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? brand.dark
                : AppColors.inkMuted,
          ),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          selectedBackgroundColor: brand.tint,
          selectedForegroundColor: brand.dark,
          foregroundColor: AppColors.inkMuted,
          side: const BorderSide(color: AppColors.border),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

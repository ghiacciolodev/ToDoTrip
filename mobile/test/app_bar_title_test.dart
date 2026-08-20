import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/core/theme/app_theme.dart';
import 'package:todotrip/core/theme/brand.dart';
import 'package:todotrip/core/theme/colors.dart';

void main() {
  group('the title on every app bar', () {
    late AppBarThemeData bar;

    setUp(() => bar = AppTheme.light(defaultBrand).appBarTheme);

    test('is bold, not the regular weight of body text', () {
      // Left to titleLarge it was 22 at regular weight, so a screen title had
      // only its size to distinguish it from a paragraph.
      expect(bar.titleTextStyle?.fontWeight, FontWeight.w700);
    });

    test('is smaller than the default it replaces', () {
      expect(bar.titleTextStyle?.fontSize, lessThan(22));
    });

    test('stays centred', () {
      expect(bar.centerTitle, isTrue);
    });

    test('uses the shipped typeface and the ink colour', () {
      // Not the system font, which would differ between phones, and not a
      // colour picked per screen.
      expect(bar.titleTextStyle?.fontFamily, 'Inter');
      expect(bar.titleTextStyle?.color, AppColors.ink);
    });

    test('is the same whatever accent the user picked', () {
      // The title is ink, not the brand colour: only one style exists.
      for (final brand in brands.values) {
        final other = AppTheme.light(brand).appBarTheme.titleTextStyle;
        expect(
          other?.fontSize,
          bar.titleTextStyle?.fontSize,
          reason: brand.key,
        );
        expect(other?.color, bar.titleTextStyle?.color, reason: brand.key);
      }
    });
  });
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/core/theme/app_theme.dart';
import 'package:todotrip/core/theme/brand.dart';

/// The accent is now a user choice, which means every one of these colours has
/// to be readable — not just the one that shipped. Contrast is measured here
/// rather than eyeballed, because a palette entry added later would otherwise
/// pass review by looking nice.
void main() {
  /// WCAG relative luminance.
  double luminance(Color colour) {
    double channel(double value) => value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(colour.r) +
        0.7152 * channel(colour.g) +
        0.0722 * channel(colour.b);
  }

  double contrast(Color a, Color b) {
    final first = luminance(a);
    final second = luminance(b);
    final lighter = math.max(first, second);
    final darker = math.min(first, second);
    return (lighter + 0.05) / (darker + 0.05);
  }

  group('every accent stays readable', () {
    for (final brand in brands.values) {
      test('${brand.key}: its dark shade carries text on white', () {
        /// 4.5:1 is the threshold for body text. This is the shade used
        /// wherever the colour carries words, which is why it is written down
        /// per brand instead of being darkened programmatically.
        expect(
          contrast(brand.dark, Colors.white),
          greaterThanOrEqualTo(4.5),
          reason: '${brand.key} dark on white',
        );
      });

      test('${brand.key}: its dark shade carries text on its own tint', () {
        expect(
          contrast(brand.dark, brand.tint),
          greaterThanOrEqualTo(4.5),
          reason: '${brand.key} dark on tint',
        );
      });

      test('${brand.key}: white shows on the fill', () {
        /// 3:1, the threshold for a shape rather than a paragraph: primary is
        /// used to fill buttons and markers.
        expect(
          contrast(Colors.white, brand.primary),
          greaterThanOrEqualTo(3.0),
          reason: '${brand.key} white on primary',
        );
      });
    }
  });

  test('the tint really is lighter than the fill', () {
    for (final brand in brands.values) {
      expect(
        luminance(brand.tint),
        greaterThan(luminance(brand.primary)),
        reason: brand.key,
      );
    }
  });

  test('an unknown stored key opens on the default', () {
    /// A build that saved a colour a later version dropped must still start.
    expect(brandFor('ultraviolet'), defaultBrand);
    expect(brandFor(null), defaultBrand);
  });

  test('the keys and the map agree', () {
    /// The key is what gets persisted, so a copy-paste slip here would make a
    /// choice unrestorable.
    for (final entry in brands.entries) {
      expect(entry.value.key, entry.key);
    }
  });

  group('the theme carries the choice', () {
    for (final brand in brands.values) {
      test('${brand.key} reaches the scheme in all three roles', () {
        /// Widgets ask the scheme, not the palette: if these three slots are
        /// not wired the substitution silently falls back to Material's own
        /// derived colours.
        final scheme = AppTheme.schemeFor(brand);
        expect(scheme.primary, brand.primary);
        expect(scheme.primaryContainer, brand.tint);
        expect(scheme.onPrimaryContainer, brand.dark);
      });
    }
  });
}

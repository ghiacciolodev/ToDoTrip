import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One accent colour, in the three roles the app actually uses it in.
///
/// The dark and tint variants are written down rather than derived at runtime.
/// Darkening a hue programmatically gets the shade roughly right and the
/// contrast wrong: several of these tones land under 4.5:1 on white, which is
/// the exact problem the brand teal already has — #2D9583 reads at 3.66:1, so
/// it may fill a shape but must never carry words. Each pair below was measured
/// against white before being added; the darks range from 6.3:1 to 10.6:1.
class Brand {
  const Brand({
    required this.key,
    required this.primary,
    required this.dark,
    required this.tint,
  });

  /// What is persisted. The colours may be retuned without invalidating
  /// anybody's stored choice.
  final String key;

  /// Fills and shapes: buttons, the FAB, a selected marker.
  final Color primary;

  /// Anything where the colour carries text or a small icon.
  final Color dark;

  /// Quiet backgrounds: a selected row, a navigation indicator.
  final Color tint;
}

const _teal = Brand(
  key: 'teal',
  primary: Color(0xFF2D9583),
  dark: Color(0xFF1C6B5D),
  tint: Color(0xFFE8F4F1),
);

/// Eight, which is two rows of four on the narrowest phone the app supports.
const brands = <String, Brand>{
  'teal': _teal,
  'blue': Brand(
    key: 'blue',
    primary: Color(0xFF3A7CA5),
    dark: Color(0xFF1F4E68),
    tint: Color(0xFFE7F0F5),
  ),
  'violet': Brand(
    key: 'violet',
    primary: Color(0xFF9B6A9D),
    dark: Color(0xFF61406B),
    tint: Color(0xFFF2EAF3),
  ),
  'rose': Brand(
    key: 'rose',
    primary: Color(0xFFC05F84),
    dark: Color(0xFF833F58),
    tint: Color(0xFFF9EAF0),
  ),
  'terracotta': Brand(
    key: 'terracotta',
    primary: Color(0xFFC2553F),
    dark: Color(0xFF8A3626),
    tint: Color(0xFFF8EAE6),
  ),
  'amber': Brand(
    key: 'amber',
    primary: Color(0xFFB07D48),
    dark: Color(0xFF74491F),
    tint: Color(0xFFF7EEE2),
  ),
  'olive': Brand(
    key: 'olive',
    primary: Color(0xFF7A8B4A),
    dark: Color(0xFF4C5A28),
    tint: Color(0xFFEFF2E5),
  ),
  'slate': Brand(
    key: 'slate',
    primary: Color(0xFF5A6663),
    dark: Color(0xFF37413F),
    tint: Color(0xFFEBEEED),
  ),
};

/// The brand teal, and what an unknown key falls back to — a build that stored
/// a colour a later version removed must still open.
const defaultBrand = _teal;

Brand brandFor(String? key) => brands[key] ?? defaultBrand;

/// Which accent the app wears.
///
/// Persisted rather than remembered per session: it is a preference about how
/// the app looks, and having it reset on every cold start would read as a bug.
class BrandController extends AsyncNotifier<Brand> {
  static const _key = 'brand';

  @override
  Future<Brand> build() async {
    final prefs = await SharedPreferences.getInstance();
    return brandFor(prefs.getString(_key));
  }

  Future<void> select(Brand brand) async {
    // Applied first: repainting the app must not wait on the disk.
    state = AsyncData(brand);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, brand.key);
  }
}

final brandProvider = AsyncNotifierProvider<BrandController, Brand>(
  BrandController.new,
);

import 'package:flutter/material.dart';

/// Brand palette.
///
/// Kept as plain constants rather than only inside ThemeData so that values can
/// be used in places where a BuildContext is awkward (painters, tests, seeds).
abstract final class AppColors {
  /// Logo colour. Fills only: at 3.7:1 on white it is below the 4.5:1 needed
  /// for text, so [primaryDark] is used wherever the colour carries words.
  static const primary = Color(0xFF2D9583);
  static const primaryDark = Color(0xFF1C6B5D);
  static const primaryTint = Color(0xFFE8F4F1);

  /// Used for money owed and destructive actions. Paired with a sign and a
  /// label, never colour alone: red/green carries no meaning for roughly 8% of
  /// men.
  static const terracotta = Color(0xFFC2553F);

  static const ink = Color(0xFF0F1715);
  static const inkMuted = Color(0xFF5A6663);
  static const border = Color(0xFFE4E8E7);
  static const background = Color(0xFFFAFBFA);
  static const surface = Colors.white;
}

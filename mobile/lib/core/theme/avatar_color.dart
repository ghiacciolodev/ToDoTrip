import 'package:flutter/material.dart';

/// Deterministic avatar colour derived from a user id.
///
/// Avoids image upload entirely in v1: initials on a stable colour give each
/// member a recognisable identity without storage, CDN or camera permissions.
Color avatarColorFor(String id) {
  const palette = [
    Color(0xFF2D9583),
    Color(0xFF3A7CA5),
    Color(0xFF9B6A9D),
    Color(0xFFC2553F),
    Color(0xFF7A8B4A),
    Color(0xFFB07D48),
  ];
  final hash = id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return palette[hash % palette.length];
}

/// Up to two initials from a display name.
String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

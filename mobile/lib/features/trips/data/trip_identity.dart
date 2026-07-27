import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// The look of a trip: an icon and a colour, chosen at creation.
///
/// The server stores symbolic keys and nothing else — no code points, no hex.
/// The mapping lives here, where the drawing happens, so changing an icon or a
/// shade never touches the database and a future web client can pick its own
/// glyphs for the same keys.
///
/// Not photos: uploads would mean storage, a CDN, resizing and camera
/// permissions, for a result that at this scale nobody would tell apart from a
/// coloured icon.
class TripIdentity {
  const TripIdentity({required this.icon, required this.colour});

  final IconData icon;
  final Color colour;

  /// What a trip looks like.
  ///
  /// The icon falls back to a skyline rather than to something derived from the
  /// id: a random glyph would claim the trip is about mountains or sailing when
  /// nobody said so, and a wrong statement reads worse than a neutral one. An
  /// unknown key — sent by a client one version ahead — lands here too instead
  /// of throwing. The colour is still derived, because there it is the absence
  /// of a choice that would show.
  factory TripIdentity.of({
    required String tripId,
    String? icon,
    String? color,
  }) {
    return TripIdentity(
      icon: tripIcons[icon] ?? _fallbackIcon,
      colour: tripColors[color] ?? _derived(tripColors.values.toList(), tripId),
    );
  }

  static const _fallbackIcon = Icons.location_city;

  static T _derived<T>(List<T> options, String id) {
    final hash = id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return options[hash % options.length];
  }
}

/// Twelve icons that cover the trips people actually take. The keys are the
/// contract with the server; the glyphs are ours to change.
const tripIcons = <String, IconData>{
  'beach': Icons.beach_access,
  'mountain': Icons.landscape,
  'city': Icons.location_city,
  'forest': Icons.forest,
  'roadtrip': Icons.directions_car,
  'flight': Icons.flight_takeoff,
  'camping': Icons.cabin,
  'festival': Icons.festival,
  'ski': Icons.downhill_skiing,
  'sail': Icons.sailing,
  'party': Icons.celebration,
  'generic': Icons.luggage,
};

/// Eight colours, all from the app's palette rather than invented per trip: a
/// list of cards should look like one product.
///
/// Written as literals, including the ones that match the brand: a trip's teal
/// is that trip's teal, and must not change under it because the reader picked
/// a different accent for the app.
const tripColors = <String, Color>{
  'teal': Color(0xFF2D9583),
  'deep': Color(0xFF1C6B5D),
  'blue': Color(0xFF3A7CA5),
  'violet': Color(0xFF9B6A9D),
  'terracotta': AppColors.terracotta,
  'olive': Color(0xFF7A8B4A),
  'amber': Color(0xFFB07D48),
  'slate': Color(0xFF5A6663),
};

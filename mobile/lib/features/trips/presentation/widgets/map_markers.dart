import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../data/map_pin.dart';

/// Marker bodies, kept deliberately plain.
///
/// Every one of these is rebuilt and repainted while the map moves, so each is
/// a single decorated box with one child: no columns, no shadows, no text under
/// the avatar. Each sits in a RepaintBoundary at the call site so one member
/// moving does not repaint the others.

/// A member, drawn with the same colour and initials they have everywhere else.
class MemberMarker extends StatelessWidget {
  const MemberMarker({
    super.key,
    required this.initials,
    required this.colour,
    this.isStale = false,
    this.isMe = false,
  });

  final String initials;
  final Color colour;

  /// Older than two minutes: shown faded, with the age spelled out in the sheet
  /// rather than in a label that would double the widget's cost.
  final bool isStale;

  /// Your own avatar, told apart by the colour of the ring rather than by a
  /// different shape: everyone on the map is a person, and they should read as
  /// the same kind of thing.
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isStale ? colour.withValues(alpha: 0.45) : colour,
        shape: BoxShape.circle,
        // A ring is what lifts an avatar off a busy map.
        border: Border.all(
          color: isMe ? AppColors.primary : Colors.white,
          width: isMe ? 3 : 2.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A saved place, shaped like a pin so it reads as a location, not a person.
class PinMarker extends StatelessWidget {
  const PinMarker({super.key, required this.category});

  final PinCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(category.icon, size: 18, color: AppColors.primaryDark),
    );
  }
}

/// The count shown when pins collapse together at low zoom.
class ClusterMarker extends StatelessWidget {
  const ClusterMarker({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

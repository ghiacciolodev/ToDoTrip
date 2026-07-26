import 'package:flutter/material.dart';

import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';

/// Overlapping avatars, capped at three plus a count.
///
/// Overlap rather than a row: a group should read as "these people" at a glance
/// without stretching wider than the text beside it. Extracted from the task
/// rows so the trip cards draw their members the same way — one widget, one
/// look, one place to change the spacing.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.people,
    this.total,
    this.size = 28,
  });

  /// Who to draw, in the order they should appear. Only the first three are
  /// shown; the rest become "+n".
  final List<AvatarPerson> people;

  /// How many there are in total, when the list is only a preview. Defaults to
  /// the number of people given.
  final int? total;

  final double size;

  static const _max = 3;

  /// Ring width scales with the avatar, so the same widget works at 22 and 34.
  double get _overlap => size * 0.32;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();

    final shown = people.take(_max).toList();
    final extra = (total ?? people.length) - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);

    return SizedBox(
      height: size,
      width: size + (count - 1) * (size - _overlap),
      child: Stack(
        children: [
          for (final (index, person) in shown.indexed)
            Positioned(
              left: index * (size - _overlap),
              child: _Bubble(
                label: initialsFor(person.name),
                colour: avatarColorFor(person.id),
                size: size,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (size - _overlap),
              child: _Bubble(
                label: '+$extra',
                colour: AppColors.inkMuted,
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}

/// The two things an avatar needs, so the widget takes neither a TripMember nor
/// a MemberPreview and works with both.
class AvatarPerson {
  const AvatarPerson({required this.id, required this.name});

  final String id;
  final String name;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.label,
    required this.colour,
    required this.size,
  });

  final String label;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: colour,
        shape: BoxShape.circle,
        // A ring in the surface colour separates overlapping bubbles.
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

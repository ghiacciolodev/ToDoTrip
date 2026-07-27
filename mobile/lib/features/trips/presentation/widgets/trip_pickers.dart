import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../data/trip_identity.dart';

/// The icon and colour choosers, shared by the creation sheet and the trip
/// settings screen. Two places offering the same choice have to offer it the
/// same way, or the second one reads as a different feature.
class PickerLabel extends StatelessWidget {
  const PickerLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// One scrolling row rather than a grid: twelve icons in a grid would push the
/// fields below it off a small screen.
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.selected,
    required this.colour,
    required this.onPick,
  });

  final String? selected;
  final Color colour;

  /// Called with the tapped key. Callers treat a repeat tap as clearing it, so
  /// skipping the step stays possible after changing your mind.
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tripIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = tripIcons.entries.elementAt(index);
          final chosen = entry.key == selected;
          return Semantics(
            selected: chosen,
            button: true,
            child: InkWell(
              onTap: () => onPick(entry.key),
              customBorder: const CircleBorder(),
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: chosen
                      ? colour.withValues(alpha: 0.14)
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: chosen ? colour : AppColors.border,
                    width: chosen ? 2 : 1,
                  ),
                ),
                child: Icon(
                  entry.value,
                  size: 22,
                  color: chosen ? colour : AppColors.inkMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The eight palette colours.
class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in tripColors.entries)
          Semantics(
            selected: entry.key == selected,
            button: true,
            child: InkWell(
              onTap: () => onPick(entry.key),
              customBorder: const CircleBorder(),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  // A ring set off the swatch rather than a tick drawn on it:
                  // a white tick disappears on the two lightest colours.
                  border: Border.all(
                    color: entry.key == selected
                        ? AppColors.ink
                        : Colors.transparent,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

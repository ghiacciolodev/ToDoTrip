import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/map_pin.dart';
import '../../providers.dart';
import 'directions.dart';

/// Drops a pin where the map was long-pressed.
///
/// Long-press is the gesture everyone already tries on a map, so it needs no
/// button and no mode to enter first.
Future<void> showCreatePinSheet(
  BuildContext context,
  String tripId,
  LatLng point,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CreatePinSheet(tripId: tripId, point: point),
  );
}

class _CreatePinSheet extends ConsumerStatefulWidget {
  const _CreatePinSheet({required this.tripId, required this.point});

  final String tripId;
  final LatLng point;

  @override
  ConsumerState<_CreatePinSheet> createState() => _CreatePinSheetState();
}

class _CreatePinSheetState extends ConsumerState<_CreatePinSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  PinCategory _category = PinCategory.other;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(mapRepositoryProvider)
          .createPin(
            tripId: widget.tripId,
            name: name,
            latitude: widget.point.latitude,
            longitude: widget.point.longitude,
            category: _category,
            description: _description.text.trim(),
          );
      ref.invalidate(mapPinsProvider(widget.tripId));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.pinNewTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _coordinates(widget.point),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.pinNameLabel,
                    hintText: l10n.pinNameHint,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  l10n.pinCategoryLabel,
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in PinCategory.values)
                      ChoiceChip(
                        avatar: Icon(
                          category.icon,
                          size: 16,
                          color: _category == category
                              ? AppColors.primaryDark
                              : AppColors.inkMuted,
                        ),
                        label: Text(category.label(l10n)),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: AppColors.primaryTint,
                        side: const BorderSide(color: AppColors.border),
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.pinNotesLabel),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.terracotta,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.pinDrop),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A saved place: what it is, who dropped it, and the way to get there.
Future<void> showPinSheet(BuildContext context, String tripId, MapPin pin) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => _PinSheet(tripId: tripId, pin: pin),
  );
}

class _PinSheet extends ConsumerWidget {
  const _PinSheet({required this.tripId, required this.pin});

  final String tripId;
  final MapPin pin;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.pinDeleteTitle(pin.name)),
        content: Text(l10n.pinDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(mapRepositoryProvider).deletePin(tripId, pin.id);
      ref.invalidate(mapPinsProvider(tripId));
      if (context.mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lookup = ref.watch(memberLookupProvider(tripId));
    final author = lookup[pin.createdBy]?.user.displayName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(pin.category.icon, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        pin.category.label(l10n),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (pin.description != null && pin.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(pin.description!, style: const TextStyle(height: 1.4)),
            ],

            const SizedBox(height: 16),
            Text(
              author == null
                  ? _coordinates(pin.point)
                  : l10n.pinAddedBy(
                      author,
                      DateFormat('d MMM').format(pin.createdAt.toLocal()),
                    ),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => openDirections(
                context,
                latitude: pin.latitude,
                longitude: pin.longitude,
                label: pin.name,
              ),
              icon: const Icon(Icons.directions, size: 20),
              label: Text(l10n.mapGetDirections),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: Text(l10n.pinDelete),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.terracotta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A member's live position: how fresh it is, and how to reach them.
Future<void> showMemberLocationSheet(
  BuildContext context,
  String tripId,
  MemberLocation location,
) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => _MemberLocationSheet(tripId: tripId, location: location),
  );
}

class _MemberLocationSheet extends ConsumerWidget {
  const _MemberLocationSheet({required this.tripId, required this.location});

  final String tripId;
  final MemberLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final member = ref.watch(memberLookupProvider(tripId))[location.userId];
    final name = member?.user.displayName ?? 'Someone';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColorFor(location.userId),
                  child: Text(
                    initialsFor(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _freshness(l10n, location.updatedAt),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => openDirections(
                context,
                latitude: location.latitude,
                longitude: location.longitude,
                label: name,
              ),
              icon: const Icon(Icons.directions, size: 20),
              label: Text(l10n.mapGetDirections),
            ),
          ],
        ),
      ),
    );
  }
}

String _coordinates(LatLng point) =>
    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

/// "Now" is a claim, so it is only made when it is true.
String _freshness(AppLocalizations l10n, DateTime at) {
  final minutes = DateTime.now().difference(at.toLocal()).inMinutes;
  if (minutes < 2) return l10n.mapRightNow;
  if (minutes < 60) return l10n.mapMinutesAgo(minutes);
  return l10n.mapLastSeen(DateFormat('HH:mm').format(at.toLocal()));
}

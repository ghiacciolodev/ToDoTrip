import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/trip.dart';
import '../../data/trip_member.dart';
import '../../providers.dart';
import '../widgets/invite_sheet.dart';
import '../widgets/member_actions.dart';
import '../../../auth/data/user.dart';

/// Members, invites and the destructive actions for one trip.
class GroupTab extends ConsumerWidget {
  const GroupTab({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trip = ref.watch(tripProvider(tripId)).value;
    // Only who is still here: former members exist to name old expenses, not to
    // be listed as part of the group.
    final members = ref.watch(activeMembersProvider(tripId));
    final me = ref.watch(myMembershipProvider(tripId));
    final isOwner = me?.role == MemberRole.owner;

    if (trip == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tripProvider(tripId));
        ref.invalidate(tripMembersProvider(tripId));
        if (isOwner) ref.invalidate(tripInvitesProvider(tripId));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _TripCard(trip: trip),
          const SizedBox(height: 24),

          _SectionLabel(l10n.groupPeopleCount(members.length)),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, member) in members.indexed) ...[
                  if (index > 0) const Divider(),
                  _MemberRow(
                    member: member,
                    isMe: member.user.id == me?.user.id,
                    // Nothing to offer a member looking at someone else, so the
                    // row stays inert rather than opening an empty sheet.
                    onTap: (isOwner || member.user.id == me?.user.id)
                        ? () =>
                              _openActions(context, ref, trip, members, member)
                        : null,
                  ),
                ],
              ],
            ),
          ),

          if (isOwner) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showInviteSheet(context, tripId),
              icon: const Icon(Icons.person_add_alt, size: 20),
              label: Text(l10n.groupInvitePeople),
            ),
          ],

          const SizedBox(height: 40),
          _SectionLabel(l10n.groupDangerZone),
          // Owners are shown Delete instead of Leave: the backend rejects an
          // owner leaving with 409, and a button that always fails is worse
          // than no button.
          if (isOwner)
            _DangerButton(
              icon: Icons.delete_outline,
              label: l10n.groupDeleteTrip,
              onPressed: () => _confirmDelete(context, ref, trip),
            )
          else
            _DangerButton(
              icon: Icons.exit_to_app,
              label: l10n.groupLeaveTrip,
              onPressed: () => confirmLeaveTrip(
                context,
                ref,
                trip: trip,
                memberCount: members.length,
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the actions for one member. What it offers depends on who the caller
  /// is and who they tapped, so the sheet decides and this only runs the choice.
  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
    List<TripMember> members,
    TripMember member,
  ) async {
    final action = await showMemberActionsSheet(
      context,
      tripId,
      member.user.id,
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case MemberAction.makeOwner:
        await confirmMakeOwner(context, ref, tripId, member);
      case MemberAction.remove:
        await confirmRemoveMember(context, ref, tripId, member);
      case MemberAction.leave:
        await confirmLeaveTrip(
          context,
          ref,
          trip: trip,
          memberCount: members.length,
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.tripDeleteTitle(trip.name)),
        // Names what is lost, and for whom: this destroys other people's
        // expense history, not just the caller's.
        content: Text(l10n.tripDeleteBody),
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
      await ref.read(tripRepositoryProvider).delete(tripId);
      ref.invalidate(tripsProvider);
      if (context.mounted) context.go('/trips');
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, friendlyError(context, e));
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _dates(context, trip),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.payments_outlined,
                  size: 15,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  trip.baseCurrency,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (trip.description != null && trip.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                trip.description!,
                style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _dates(BuildContext context, Trip trip) {
    final full = DateFormat('d MMM y');
    final start = trip.startDate;
    final end = trip.endDate;
    if (start == null && end == null) {
      return AppLocalizations.of(context).tripNoDates;
    }
    if (start != null && end != null) {
      return '${DateFormat('d MMM').format(start)} – ${full.format(end)}';
    }
    return full.format(start ?? end!);
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isMe, this.onTap});

  final TripMember member;
  final bool isMe;

  /// Null when the caller has no action available on this person.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: avatarColorFor(member.user.id),
        child: Text(
          initialsFor(
            member.user.nameOrNull ??
                AppLocalizations.of(context).commonUnknown,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.user.nameOrNull ??
                  AppLocalizations.of(context).commonUnknown,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            const Text(
              '(you)',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
        ],
      ),
      subtitle: Text(
        AppLocalizations.of(
          context,
        ).groupJoined(DateFormat('d MMM').format(member.joinedAt)),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.role == MemberRole.owner) const _OwnerBadge(),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.more_horiz, size: 20, color: AppColors.inkMuted),
          ],
        ],
      ),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppLocalizations.of(context).commonOwner,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.terracotta,
        side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

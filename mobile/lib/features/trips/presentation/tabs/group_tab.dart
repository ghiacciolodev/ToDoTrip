import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/trip.dart';
import '../../data/trip_member.dart';
import '../../providers.dart';
import '../widgets/invite_sheet.dart';

/// Members, invites and the destructive actions for one trip.
class GroupTab extends ConsumerWidget {
  const GroupTab({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider(tripId)).value;
    final members = ref.watch(tripMembersProvider(tripId)).value ?? const [];
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

          _SectionLabel('${members.length} ${members.length == 1 ? 'person' : 'people'}'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, member) in members.indexed) ...[
                  if (index > 0) const Divider(),
                  _MemberRow(member: member, isMe: member.user.id == me?.user.id),
                ],
              ],
            ),
          ),

          if (isOwner) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showInviteSheet(context, tripId),
              icon: const Icon(Icons.person_add_alt, size: 20),
              label: const Text('Invite people'),
            ),
          ],

          const SizedBox(height: 40),
          const _SectionLabel('Danger zone'),
          // Owners are shown Delete instead of Leave: the backend rejects an
          // owner leaving with 409, and a button that always fails is worse
          // than no button.
          if (isOwner)
            _DangerButton(
              icon: Icons.delete_outline,
              label: 'Delete trip',
              onPressed: () => _confirmDelete(context, ref, trip),
            )
          else
            _DangerButton(
              icon: Icons.exit_to_app,
              label: 'Leave trip',
              onPressed: () => _confirmLeave(context, ref, trip),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref, Trip trip) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text('Leave ${trip.name}?'),
        content: const Text(
          "You'll lose access to the plan and expenses. "
              'Anything you already added stays with the group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(tripRepositoryProvider).leave(tripId);
      ref.invalidate(tripsProvider);
      if (context.mounted) context.go('/trips');
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Trip trip) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text('Delete ${trip.name}?'),
        // Names what is lost, and for whom: this destroys other people's
        // expense history, not just the caller's.
        content: const Text(
          'This permanently deletes the plan, every expense and everyone\u2019s '
              'balances. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.terracotta)),
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
      if (context.mounted) _toast(context, e.message);
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  _dates(trip),
                  style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.payments_outlined,
                    size: 15, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  trip.baseCurrency,
                  style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
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

  static String _dates(Trip trip) {
    final full = DateFormat('d MMM y');
    final start = trip.startDate;
    final end = trip.endDate;
    if (start == null && end == null) return 'No dates yet';
    if (start != null && end != null) {
      return '${DateFormat('d MMM').format(start)} – ${full.format(end)}';
    }
    return full.format(start ?? end!);
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isMe});

  final TripMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColorFor(member.user.id),
        child: Text(
          initialsFor(member.user.displayName),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.user.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            const Text('(you)', style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
          ],
        ],
      ),
      subtitle: Text(
        'Joined ${DateFormat('d MMM').format(member.joinedAt)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: member.role == MemberRole.owner ? const _OwnerBadge() : null,
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
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Owner',
        style: TextStyle(
          color: AppColors.primaryDark,
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
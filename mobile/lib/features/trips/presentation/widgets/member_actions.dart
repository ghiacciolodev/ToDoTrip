import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/trip.dart';
import '../../data/trip_member.dart';
import '../../providers.dart';

/// Managing who is in a trip.
///
/// Three rules shape everything here: a trip always has exactly one owner, an
/// owner cannot step out without handing it over, and nobody leaves with an open
/// balance — their expenses cannot be deleted, and once they are gone the app has
/// no name to put next to the debt and no way to settle it.
enum MemberAction { makeOwner, remove, leave }

/// Shows what the caller may do to this member and returns their choice.
///
/// Only the choice: the confirmations and the requests run in the caller's
/// context, which survives the sheet closing and can still navigate afterwards.
Future<MemberAction?> showMemberActionsSheet(
    BuildContext context,
    String tripId,
    String userId,
    ) {
  return showModalBottomSheet<MemberAction>(
    context: context,
    builder: (_) => _MemberActionsSheet(tripId: tripId, userId: userId),
  );
}

class _MemberActionsSheet extends ConsumerWidget {
  const _MemberActionsSheet({required this.tripId, required this.userId});

  final String tripId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(activeMembersProvider(tripId));
    final me = ref.watch(myMembershipProvider(tripId));

    TripMember? target;
    for (final member in members) {
      if (member.user.id == userId) target = member;
    }

    // Removed by someone else while the sheet was opening.
    if (target == null || me == null) {
      return const _Sheet(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'This person is no longer in the trip.',
              style: TextStyle(color: AppColors.inkMuted),
            ),
          ),
        ],
      );
    }

    final isMe = target.user.id == me.user.id;
    final iAmOwner = me.role == MemberRole.owner;
    // An owner with company has to hand the trip over first; alone, leaving
    // deletes the trip, which is allowed.
    final blockedByOwnership = isMe && iAmOwner && members.length > 1;

    return _Sheet(
      children: [
        _Header(member: target, isMe: isMe),
        const SizedBox(height: 8),

        if (iAmOwner && !isMe) ...[
          _ActionRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Make owner',
            detail: 'They take over the trip, you become a member.',
            onTap: () => Navigator.of(context).pop(MemberAction.makeOwner),
          ),
          _ActionRow(
            icon: Icons.person_remove_outlined,
            label: 'Remove from trip',
            detail: 'They lose access immediately.',
            destructive: true,
            onTap: () => Navigator.of(context).pop(MemberAction.remove),
          ),
        ] else if (isMe) ...[
          _ActionRow(
            icon: Icons.exit_to_app,
            label: members.length == 1 ? 'Leave and delete trip' : 'Leave trip',
            detail: blockedByOwnership
                ? "You're the owner. Make someone else the owner first."
                : members.length == 1
                ? "You're the only one left, so the trip goes too."
                : null,
            destructive: true,
            onTap: blockedByOwnership
                ? null
                : () => Navigator.of(context).pop(MemberAction.leave),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Only the owner can manage members.',
              style: TextStyle(color: AppColors.inkMuted),
            ),
          ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.member, required this.isMe});

  final TripMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: avatarColorFor(member.user.id),
          child: Text(
            initialsFor(member.user.displayName),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? '${member.user.displayName} (you)' : member.user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                member.role == MemberRole.owner ? 'Owner' : 'Member',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? detail;

  /// Null disables the row: the reason is in [detail], which is more use than a
  /// button that fails when tapped.
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colour = !enabled
        ? AppColors.inkMuted
        : destructive
        ? AppColors.terracotta
        : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colour),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colour,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(
    BuildContext context, {
      required String title,
      required String message,
      required String action,
      bool destructive = true,
    }) async {
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            action,
            style: TextStyle(
              color: destructive ? AppColors.terracotta : AppColors.primaryDark,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// A blocked action explained in its own dialog rather than a snack bar: it
/// names an amount and a person, and it has to stay on screen long enough to be
/// read and acted on.
Future<void> _explain(BuildContext context, String title, String message) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Turns an `outstanding_balance` conflict into the sentence the user needs:
/// who, how much, and which direction.
String _balanceMessage(
    ApiException error, {
      required String name,
      required bool isYou,
      required String action,
    }) {
  final cents = (error.details?['balance_cents'] as num?)?.toInt() ?? 0;
  final amount = Money(cents.abs()).formatted;
  final owing = cents < 0;

  final who = isYou
      ? (owing ? 'You owe $amount' : "You're owed $amount")
      : (owing ? '$name owes $amount' : '$name is owed $amount');

  return '$who. Settle up before $action.';
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> confirmMakeOwner(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    TripMember target,
    ) async {
  final name = target.user.displayName;
  final confirmed = await _confirm(
    context,
    title: 'Make $name the owner?',
    // Says what is given up, not just what is granted: this is one-way unless
    // the new owner hands it back.
    message: '$name will be able to invite people, remove members and delete '
        'the trip. You become a regular member, and only $name can give it back.',
    action: 'Make owner',
    destructive: false,
  );
  if (!confirmed || !context.mounted) return;

  try {
    await ref.read(tripRepositoryProvider).makeOwner(tripId, target.user.id);
    ref.invalidate(tripMembersProvider(tripId));
  } on ApiException catch (e) {
    if (context.mounted) _toast(context, e.message);
  }
}

Future<void> confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    TripMember target,
    ) async {
  final name = target.user.displayName;
  final confirmed = await _confirm(
    context,
    title: 'Remove $name?',
    message: 'They lose access to this trip immediately. What they added stays: '
        'expenses, tasks and everyone else’s balances are untouched.',
    action: 'Remove',
  );
  if (!confirmed || !context.mounted) return;

  try {
    await ref.read(tripRepositoryProvider).removeMember(tripId, target.user.id);
    ref.invalidate(tripMembersProvider(tripId));
    // Their task assignments are gone with them; the tasks themselves remain.
    ref.invalidate(itemsProvider(tripId));
  } on ApiException catch (e) {
    if (!context.mounted) return;
    if (e.code == 'outstanding_balance') {
      await _explain(
        context,
        'Not settled up',
        _balanceMessage(e, name: name, isYou: false, action: 'removing them'),
      );
    } else {
      _toast(context, e.message);
    }
  }
}

/// Leaves the trip — or deletes it, when the caller is the last member.
Future<void> confirmLeaveTrip(
    BuildContext context,
    WidgetRef ref, {
      required Trip trip,
      required int memberCount,
    }) async {
  final alone = memberCount <= 1;
  final confirmed = await _confirm(
    context,
    title: alone ? 'Leave and delete ${trip.name}?' : 'Leave ${trip.name}?',
    message: alone
        ? "You're the only one left. Leaving will delete this trip and "
        'everything in it: expenses, calendar, tasks and lists. '
        'It cannot be undone.'
        : "You'll lose access to the plan and expenses. Anything you already "
        'added stays with the group.',
    action: alone ? 'Leave and delete' : 'Leave',
  );
  if (!confirmed || !context.mounted) return;

  try {
    await ref.read(tripRepositoryProvider).leave(trip.id);
    ref.invalidate(tripsProvider);
    if (context.mounted) context.go('/trips');
  } on ApiException catch (e) {
    if (!context.mounted) return;
    switch (e.code) {
      case 'outstanding_balance':
        await _explain(
          context,
          'Not settled up',
          _balanceMessage(e, name: 'You', isYou: true, action: 'leaving'),
        );
      case 'owner_must_transfer':
        await _explain(
          context,
          "You're the owner",
          'Make someone else the owner before leaving, so the group keeps '
              'someone who can manage the trip.',
        );
      default:
        _toast(context, e.message);
    }
  }
}

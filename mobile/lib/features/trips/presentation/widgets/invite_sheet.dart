import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/colors.dart';
import '../../data/invite.dart';
import '../../providers.dart';

Future<void> showInviteSheet(BuildContext context, String tripId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _InviteSheet(tripId: tripId),
  );
}

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.tripId});

  final String tripId;

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  bool _creating = false;

  Future<void> _createCode() async {
    setState(() => _creating = true);
    try {
      await ref.read(tripRepositoryProvider).createInvite(widget.tripId);
      ref.invalidate(tripInvitesProvider(widget.tripId));
    } on ApiException catch (e) {
      if (mounted) _toast(friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _revoke(Invite invite) async {
    try {
      await ref
          .read(tripRepositoryProvider)
          .revokeInvite(widget.tripId, invite.id);
      ref.invalidate(tripInvitesProvider(widget.tripId));
    } on ApiException catch (e) {
      if (mounted) _toast(friendlyError(context, e));
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invites = ref.watch(tripInvitesProvider(widget.tripId));
    final active = (invites.value ?? const <Invite>[])
        .where((i) => i.isActive)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.inviteTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.inviteBody,
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),

              if (invites.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                )
              else if (active.isEmpty)
                FilledButton.icon(
                  onPressed: _creating ? null : _createCode,
                  icon: _creating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 20),
                  label: Text(l10n.inviteCreate),
                )
              else
                for (final invite in active) ...[
                  _CodeCard(invite: invite, onRevoke: () => _revoke(invite)),
                  const SizedBox(height: 12),
                ],

              if (active.isNotEmpty) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _creating ? null : _createCode,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.inviteNewCode),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.invite, required this.onRevoke});

  final Invite invite;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Wide letter spacing because these codes get read out loud as often
          // as they get copied.
          Text(
            invite.code,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            invite.usesCount == 0
                ? l10n.inviteNotUsedYet
                : l10n.inviteUsedCount(invite.usesCount),
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invite.code));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.inviteCodeCopied)),
                      );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.commonCopy),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Revoking matters: a code shared in the wrong chat has to be
              // killable.
              IconButton.outlined(
                onPressed: onRevoke,
                tooltip: l10n.inviteRevoke,
                icon: const Icon(Icons.link_off, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(46, 46),
                  foregroundColor: AppColors.terracotta,
                  side: BorderSide(
                    color: AppColors.terracotta.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

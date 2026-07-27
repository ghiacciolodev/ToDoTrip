import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers.dart';

/// The bell in the app bar, with a dot when there is something unread.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Zero while the count is still loading or has failed: a badge that appears
    // and then vanishes is worse than one that arrives a moment late.
    final count = ref.watch(unreadCountProvider).value ?? 0;

    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () => context.push('/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none),
          if (count > 0)
            Positioned(
              right: -4,
              top: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(9),
                  // A ring in the app bar's colour, so the badge reads as
                  // sitting on top of the bell rather than merged into it.
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Text(
                  // Past nine it stops being a number and becomes "a lot".
                  // Three digits in a badge this size are unreadable and,
                  // worse, alarming.
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

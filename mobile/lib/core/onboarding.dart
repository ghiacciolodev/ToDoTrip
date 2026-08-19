import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the introduction has been seen.
///
/// Kept on the device rather than on the account, because it is a fact about
/// this phone and not about the person: somebody who already knows the app and
/// signs in on a new handset is not asking to be taught it again, but somebody
/// reinstalling has lost the tour along with everything else.
///
/// Null while the answer is still being read off the disk, which the router
/// treats as "do not decide yet" — showing the tour for one frame to somebody
/// who has already dismissed it would be worse than a moment of splash.
class OnboardingSeen extends AsyncNotifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    // Set in memory first: the router reacts to this, and the redirect should
    // not wait on a disk write.
    state = const AsyncData(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

final onboardingSeenProvider = AsyncNotifierProvider<OnboardingSeen, bool>(
  OnboardingSeen.new,
);

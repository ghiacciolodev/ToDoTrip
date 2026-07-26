import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/user.dart';
import 'network/api_exception.dart';
import 'network/dio_client.dart';
import 'storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  return createDio(
    storage: ref.watch(tokenStorageProvider),
    // When the refresh token is dead there is nothing left to try: drop the
    // session and the router redirects to sign-in on the next frame.
    onSessionExpired: () async => ref.read(authProvider.notifier).forceLogout(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});

/// Session state. Null means signed out.
///
/// This provider represents the session only. Transient UI concerns — a login
/// in flight, a rejected password — belong to the screen: emitting them here
/// would make the router react to them and rebuild the navigator mid-typing.
///
/// AsyncNotifier because the initial value is genuinely asynchronous: on cold
/// start the app must ask the API whether the stored token is still valid.
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.watch(tokenStorageProvider);
    if (await storage.readAccess() == null) return null;
    try {
      return await ref.watch(authRepositoryProvider).me();
    } on ApiException {
      // Expired or revoked while the app was closed.
      await storage.clear();
      return null;
    }
  }

  /// Throws [ApiException] on failure so the caller can render it in place.
  Future<void> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.login(email: email, password: password);
    state = AsyncData(await repo.me());
  }

  /// Registers, then signs in: the API returns a user, not a token pair.
  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    await repo.login(email: email, password: password);
    state = AsyncData(await repo.me());
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Called by the interceptor when refreshing failed: tokens are already gone
  /// server-side, so only local state needs clearing.
  Future<void> forceLogout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

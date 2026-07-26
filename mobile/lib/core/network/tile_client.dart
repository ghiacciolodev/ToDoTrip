import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies the app to OpenStreetMap, as their tile usage policy requires.
const tileUserAgent = 'TodoTrip/0.1 (github.com/ghiacciolodev/todotrip)';

/// Tiles are cached in memory for the session.
///
/// A disk cache would be better and is what this was meant to be, but every
/// published on-disk store (`dio_cache_interceptor_file_store`, the Hive one)
/// still pins `dio_cache_interceptor ^3`, while `flutter_map_cache` requires
/// `^4`. When one of them catches up this becomes a one-line swap. In the
/// meantime panning back over ground already covered costs nothing, which is
/// the case that hurt.
final tileCacheStoreProvider = Provider<CacheStore>((ref) {
  final store = MemCacheStore(maxSize: 48 << 20, maxEntrySize: 512 << 10);
  ref.onDispose(store.close);
  return store;
});

/// A Dio for map tiles only — deliberately **not** the app's client.
///
/// The application client attaches the session token to every request through
/// its interceptor. Reusing it here would send that token to a third-party tile
/// server on every one of the hundreds of tile requests a map makes. Tiles are
/// public, unauthenticated data and travel on their own client.
final tileDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      headers: {'User-Agent': tileUserAgent},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    DioCacheInterceptor(
      options: CacheOptions(
        store: ref.watch(tileCacheStoreProvider),
        // Tiles for a city change on the scale of months, so a stored one is
        // used without asking the server first.
        policy: CachePolicy.forceCache,
        maxStale: const Duration(days: 30),
        // Panning through a tunnel keeps showing what was already seen instead
        // of a grid of grey squares.
        hitCacheOnNetworkFailure: true,
        hitCacheOnErrorCodes: const [500, 502, 503, 504],
      ),
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});

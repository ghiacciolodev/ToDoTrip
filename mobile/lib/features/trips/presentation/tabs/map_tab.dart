import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/tile_client.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/location_sharing.dart';
import '../../data/map_pin.dart';
import '../../providers.dart';
import '../widgets/map_markers.dart';
import '../widgets/pin_sheets.dart';

/// The trip's map: where its places are, and who is out there right now.
///
/// Three independent things share this screen — the map itself, the shared
/// pins, and live member positions — and each is watched by its own widget.
/// The tile layer is built once and never rebuilt: the usual reason a map
/// stutters is that a GPS fix at 3Hz rebuilds the whole tree, tiles included.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key, required this.tripId, required this.isVisible});

  final String tripId;

  /// The tab lives inside an IndexedStack, so it stays mounted when the user
  /// looks at expenses. The GPS must not: this is what turns it off.
  final bool isVisible;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Created here, never in build: a controller rebuilt mid-gesture loses the
  // camera and the animation with it.
  final _controller = MapController();

  LocationSharer? _sharer;
  bool _sharing = false;
  LocationBlock? _blocked;

  /// Where this device is, as far as it knows. A notifier for the same reason
  /// the members are: a fix every few seconds must redraw one dot, not the map.
  ///
  /// Known locally is not the same as shared: this is filled whenever the OS
  /// will say where we are, while the server hears nothing until the switch is
  /// on.
  final _myPoint = ValueNotifier<LatLng?>(null);

  /// Whether the camera should keep up with the dot.
  ///
  /// On while sharing, off the instant the user drags the map: fighting someone
  /// who is looking at where their friends are is worse than not following at
  /// all. The recentre button turns it back on.
  bool _following = false;

  /// Keeps the map alive across tab switches so it does not reload every time.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sharer = LocationSharer(
      tripId: widget.tripId,
      repository: ref.read(mapRepositoryProvider),
    );
    _loadLocations();
    _seedMyPosition();
  }

  /// Shows the user's own dot when the OS will already answer, and asks for
  /// nothing when it will not.
  ///
  /// A map that fires a permission prompt the moment it opens teaches people to
  /// press Deny. Until they either share or tap "centre on me", no prompt.
  Future<void> _seedMyPosition() async {
    // While sharing, the stream is the better source and this would drag the
    // dot back to wherever the cached fix was.
    if (_sharing) return;

    final permission = await Geolocator.checkPermission();
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!granted || !await Geolocator.isLocationServiceEnabled()) return;

    try {
      // The cached fix only fills an empty map, because it can be days old.
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null && mounted && _myPoint.value == null) {
        _myPoint.value = LatLng(cached.latitude, cached.longitude);
      }

      // Then a real reading corrects it, which is what makes the dot move on a
      // device that has been sitting still since the app last ran.
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted || _sharing) return;
      _myPoint.value = LatLng(fix.latitude, fix.longitude);
    } on Exception {
      // No fix available: the map opens on the default view instead.
    }
  }

  @override
  void didUpdateWidget(covariant MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Leaving the tab stops the GPS; coming back does not silently restart it,
    // because sharing is a decision the user made and must make again.
    if (oldWidget.isVisible && !widget.isVisible && _sharing) {
      _stopSharing();
    }
    // Opening the map is the moment you ask "where is everyone", and whoever
    // started sharing while this tab sat in the background was only announced
    // over the socket — which may have been asleep.
    if (!oldWidget.isVisible && widget.isVisible) {
      _loadLocations();
      _seedMyPosition();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Foreground only, always: no background permission is ever requested, so
    // there is nothing to keep running once the app is not on screen.
    if (state == AppLifecycleState.paused && _sharing) _stopSharing();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sharer?.stop();
    _myPoint.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Seeds the live positions with whoever is already sharing; from then on the
  /// websocket keeps them current.
  Future<void> _loadLocations() async {
    try {
      final locations = await ref
          .read(mapRepositoryProvider)
          .locations(widget.tripId);
      if (!mounted) return;
      ref.read(memberLocationsProvider(widget.tripId)).value = {
        for (final location in locations) location.userId: location,
      };
    } on Exception {
      // The map is still useful without them, and the socket will fill it in.
    }
  }

  Future<void> _toggleSharing(bool on) async {
    if (!on) {
      await _stopSharing();
      return;
    }

    final blocked = await _sharer!.start(onFix: _onFix);
    if (!mounted) return;

    setState(() {
      _blocked = blocked;
      _sharing = blocked == null;
    });
    if (blocked == null) {
      _following = true;
      await _centreOnMe();
    }
  }

  void _onFix(Position position) {
    final point = LatLng(position.latitude, position.longitude);
    _myPoint.value = point;
    if (!_following) return;

    // Keeps the zoom the user chose; only the centre follows.
    try {
      _controller.move(point, _controller.camera.zoom);
    } on Exception {
      // The map is not laid out yet; the next fix will do it.
    }
  }

  Future<void> _stopSharing() async {
    await _sharer?.stop();
    if (mounted) {
      setState(() {
        _sharing = false;
        _following = false;
      });
    }
  }

  Future<void> _centreOnMe() async {
    var point = _myPoint.value;
    if (point == null) {
      // An explicit tap is the one moment asking for permission is expected.
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        final position =
            await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition();
        point = LatLng(position.latitude, position.longitude);
        if (!mounted) return;
        _myPoint.value = point;
      } on Exception {
        return;
      }
    }
    // An explicit recentre also means "keep up with me from now on".
    _following = _sharing;
    _controller.move(point, 15);
  }

  /// Frames everyone currently on the map, so "where is everybody" is one tap.
  /// Any drag or pinch means the user is looking somewhere on purpose.
  void _onCameraMoved(MapCamera camera, bool hasGesture) {
    if (hasGesture && _following) _following = false;
  }

  void _fitEveryone() {
    // Framing the group is a deliberate look elsewhere, so stop following.
    _following = false;
    final locations = ref
        .read(memberLocationsProvider(widget.tripId))
        .value
        .values;
    final points = [
      for (final location in locations) location.point,
      ?_myPoint.value,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(64),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            // Rome at continent zoom is the fallback when the device says
            // nothing: a map has to open on something.
            initialCenter: _myPoint.value ?? const LatLng(41.9028, 12.4964),
            initialZoom: _myPoint.value == null ? 4 : 15,
            // Below 3 the world repeats; above 18 OSM has no tiles and the
            // requests are wasted.
            minZoom: 3,
            maxZoom: 18,
            onLongPress: (_, point) =>
                showCreatePinSheet(context, widget.tripId, point),
            onPositionChanged: _onCameraMoved,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            _TileLayer(tripId: widget.tripId),
            _PinLayer(tripId: widget.tripId),
            _MemberLayer(tripId: widget.tripId),
            _MyLocationLayer(tripId: widget.tripId, point: _myPoint),
            const _Attribution(),
          ],
        ),
        _SharingBar(
          sharing: _sharing,
          blocked: _blocked,
          onChanged: _toggleSharing,
        ),
        _MapButtons(onCentreOnMe: _centreOnMe, onFitEveryone: _fitEveryone),
        _EmptyHint(tripId: widget.tripId),
      ],
    );
  }
}

/// Built once. Nothing above it may rebuild, or every tile is thrown away and
/// fetched again.
class _TileLayer extends ConsumerWidget {
  const _TileLayer({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.ghiacciolo.todotrip',
      maxNativeZoom: 18,
      tileProvider: CachedTileProvider(
        dio: ref.watch(tileDioProvider),
        store: ref.watch(tileCacheStoreProvider),
      ),
    );
  }
}

/// Saved places, clustered so twenty pins at city zoom stay readable.
class _PinLayer extends ConsumerWidget {
  const _PinLayer({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(mapPinsProvider(tripId)).value ?? const <MapPin>[];
    if (pins.isEmpty) return const SizedBox.shrink();

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 45,
        size: const Size(38, 38),
        markers: [
          for (final pin in pins)
            Marker(
              point: pin.point,
              width: 34,
              height: 34,
              // The tip of the pin is what points at the place.
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                child: GestureDetector(
                  onTap: () => showPinSheet(context, tripId, pin),
                  child: PinMarker(category: pin.category),
                ),
              ),
            ),
        ],
        builder: (context, markers) => ClusterMarker(count: markers.length),
      ),
    );
  }
}

/// Live positions, the only layer that redraws every twenty seconds.
///
/// A ValueListenableBuilder rather than a provider watch: the rebuild stops
/// here, and the tiles underneath never hear about it.
class _MemberLayer extends ConsumerWidget {
  const _MemberLayer({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(memberLocationsProvider(tripId));
    final lookup = ref.watch(memberLookupProvider(tripId));
    final myId = ref.watch(authProvider).value?.id;

    return ValueListenableBuilder(
      valueListenable: locations,
      builder: (context, value, _) => MarkerLayer(
        markers: [
          for (final location in value.values)
            // Your own dot is not news to you, and it would sit under the
            // recentre button anyway.
            if (location.userId != myId)
              Marker(
                point: location.point,
                width: 36,
                height: 36,
                child: RepaintBoundary(
                  child: GestureDetector(
                    onTap: () =>
                        showMemberLocationSheet(context, tripId, location),
                    child: MemberMarker(
                      initials: initialsFor(
                        lookup[location.userId]?.user.displayName ?? '?',
                      ),
                      colour: avatarColorFor(location.userId),
                      isStale: location.isStale,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// The user's own dot.
///
/// Its own layer, fed by its own notifier, because it updates on every fix —
/// several times a minute while walking — and nothing else on the map should
/// redraw for it. Drawn whether or not sharing is on: knowing where you are is
/// what makes the rest of the map readable, and it never leaves the device
/// until the switch says so.
class _MyLocationLayer extends ConsumerWidget {
  const _MyLocationLayer({required this.tripId, required this.point});

  final String tripId;
  final ValueListenable<LatLng?> point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authProvider).value;
    if (me == null) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: point,
      builder: (context, value, _) => MarkerLayer(
        markers: [
          if (value != null)
            Marker(
              point: value,
              width: 36,
              height: 36,
              child: RepaintBoundary(
                child: MemberMarker(
                  initials: initialsFor(me.displayName),
                  colour: avatarColorFor(me.id),
                  isMe: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Required by the OpenStreetMap tile usage policy.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return const RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
    );
  }
}

/// The switch, and the state of sharing spelled out next to it.
///
/// Off by default and never implicit: an app that quietly tells your friends
/// where you are is a problem, not a feature.
class _SharingBar extends StatelessWidget {
  const _SharingBar({
    required this.sharing,
    required this.blocked,
    required this.onChanged,
  });

  final bool sharing;
  final LocationBlock? blocked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      sharing ? Icons.location_on : Icons.location_off_outlined,
                      size: 20,
                      color: sharing
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : AppColors.inkMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sharing ? l10n.mapShareOn : l10n.mapShareOff,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: sharing ? AppColors.ink : AppColors.inkMuted,
                        ),
                      ),
                    ),
                    Switch(value: sharing, onChanged: onChanged),
                  ],
                ),
                if (sharing)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 8,
                      bottom: 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.mapShareForegroundOnly,
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (blocked != null && !sharing)
                  _BlockedNotice(blocked: blocked!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Each refusal needs a different way out, so each says its own thing.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({required this.blocked});

  final LocationBlock blocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (message, action) = switch (blocked) {
      LocationBlock.servicesOff => (l10n.mapServicesOff, null),
      LocationBlock.denied => (l10n.mapPermissionDenied, null),
      LocationBlock.deniedForever => (
        l10n.mapPermissionBlocked,
        l10n.mapOpenSettings,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.terracotta, fontSize: 12),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: Geolocator.openAppSettings,
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

class _MapButtons extends StatelessWidget {
  const _MapButtons({required this.onCentreOnMe, required this.onFitEveryone});

  final VoidCallback onCentreOnMe;
  final VoidCallback onFitEveryone;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          _RoundButton(
            icon: Icons.people_outline,
            tooltip: AppLocalizations.of(context).mapFitEveryone,
            onPressed: onFitEveryone,
          ),
          const SizedBox(height: 10),
          _RoundButton(
            icon: Icons.my_location,
            tooltip: AppLocalizations.of(context).mapCentreOnMe,
            onPressed: onCentreOnMe,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppColors.ink),
        tooltip: tooltip,
      ),
    );
  }
}

/// Says what the map is for while it has nothing on it.
class _EmptyHint extends ConsumerWidget {
  const _EmptyHint({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(mapPinsProvider(tripId)).value ?? const <MapPin>[];
    final locations = ref.watch(memberLocationsProvider(tripId));

    return ValueListenableBuilder(
      valueListenable: locations,
      builder: (context, value, _) {
        if (pins.isNotEmpty || value.isNotEmpty) return const SizedBox.shrink();
        return Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context).mapEmptyHint,
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

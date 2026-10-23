import 'dart:async';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/claim_map/data/providers/claim_map_providers.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';
import 'package:trash/features/claim_map/presentation/controllers/claim_map_controller.dart';
import 'package:trash/features/claim_map/presentation/widgets/impact_stats_banner.dart';
import 'package:trash/features/claim_map/presentation/widgets/map_filter_bar.dart';
import 'package:trash/features/claim_map/presentation/widgets/pin_detail_sheet.dart';

class ClaimMapScreen extends ConsumerStatefulWidget {
  const ClaimMapScreen({super.key});

  @override
  ConsumerState<ClaimMapScreen> createState() => _ClaimMapScreenState();
}

class _ClaimMapScreenState extends ConsumerState<ClaimMapScreen> {

  // Default: Algiers
  static const _defaultCenter = LatLng(36.7538, 3.0588);
  static const _defaultZoom = 13.0;

  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _goToUserLocation();
  }

  Future<void> _goToUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), _defaultZoom);
    } catch (_) {}
  }

  // Build flutter_map Markers from ClaimPins
  List<Marker> _buildMarkers(
      List<ClaimPin> ownPins,
      List<ClaimPin> friendPins,
      MapFilter filter,
      ClaimPin? selectedPin,
      ) {
    final pins = <ClaimPin>[];

    switch (filter) {
      case MapFilter.mine:
        pins.addAll(ownPins);
        break;
      case MapFilter.friends:
        pins.addAll(friendPins);
        break;
      case MapFilter.thisWeek:
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        pins.addAll([...ownPins, ...friendPins]
            .where((p) => p.claimedAt.isAfter(weekAgo)));
        break;
      case MapFilter.all:
        pins.addAll([...ownPins, ...friendPins]);
        break;
    }

    return pins.map((pin) {
      final isOwn = pin.isOwn;
      final isSelected = selectedPin?.id == pin.id;
      final color = isOwn ? AppColors.accentGreen : const Color(0xFF4D9FFF);

      return Marker(
        point: LatLng(pin.latitude, pin.longitude),
        width: isSelected ? 56 : 46,
        height: isSelected ? 56 : 46,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(claimMapNotifierProvider.notifier).selectPin(pin);
          },
          child: _PinWidget(
            emoji: pin.category.emoji,
            color: color,
            size: isSelected ? 56 : 46,
            isSelected: isSelected,
          ),
        ),
      );
    }).toList();
  }

  // Build heat circles as CircleLayer
  List<CircleMarker> _buildHeatCircles(List<HeatZone> zones, bool visible) {
    if (!visible) return [];

    return zones.map((zone) {
      final alpha = (zone.intensity * 0.45).clamp(0.08, 0.45);
      final radius = (60.0 + zone.claimCount * 8.0).clamp(60.0, 300.0);

      return CircleMarker(
        point: LatLng(zone.latitude, zone.longitude),
        radius: radius,
        useRadiusInMeter: true,
        color: Color.fromRGBO(255, 107, 44, alpha),
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    final mapState = ref.watch(claimMapNotifierProvider);
    final ownPinsAsync = ref.watch(ownPinsProvider(userId));
    final friendPinsAsync = ref.watch(friendPinsProvider(userId));
    final impactAsync = ref.watch(userImpactStatsProvider(userId));

    final ownPins = ownPinsAsync.valueOrNull ?? [];
    final friendPins = friendPinsAsync.valueOrNull ?? [];

    final markers = _buildMarkers(
      ownPins,
      friendPins,
      mapState.activeFilter,
      mapState.selectedPin,
    );

    final heatCircles = _buildHeatCircles(
      mapState.heatZones,
      mapState.showHeatMap,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── flutter_map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              backgroundColor: const Color(0xFF080E0B),
              onTap: (_, __) =>
                  ref.read(claimMapNotifierProvider.notifier).clearPin(),
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  // Load heat zones for new visible region
                  final bounds = _mapCtrl.camera.visibleBounds;
                  ref.read(claimMapNotifierProvider.notifier).loadHeatZones(
                    swLat: bounds.south,
                    swLng: bounds.west,
                    neLat: bounds.north,
                    neLng: bounds.east,
                  );
                }
              },
            ),
            children: [
              // OpenStreetMap dark tile layer (Stadia Alidade Smooth Dark)
              // No API key needed for basic OSM tiles:
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yourname.trash',
                maxZoom: 19,
              ),

              // Heat circles layer
              if (heatCircles.isNotEmpty)
                CircleLayer(circles: heatCircles),

              // Claim pins
              MarkerLayer(markers: markers),

              // Current location blue dot
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: const DefaultLocationMarker(
                    color: AppColors.accentGreen,
                    child: Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 12),
                  ),
                  markerSize: const Size(28, 28),
                  accuracyCircleColor:
                  AppColors.accentGreen.withOpacity(0.12),
                  headingSectorColor:
                  AppColors.accentGreen.withOpacity(0.4),
                ),
              ),

              // OSM attribution (required by usage policy)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {}, // optionally open browser
                  ),
                ],
                alignment: AttributionAlignment.bottomLeft,
              ),
            ],
          ),

          // ── Top controls overlay ───────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background.withOpacity(0.95),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Text('Claim Map',
                              style: AppTextStyles.headlineLarge),
                          const Spacer(),
                          _MapButton(
                            icon: Icons.my_location_rounded,
                            onTap: _goToUserLocation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                MapFilterBar(
                  active: mapState.activeFilter,
                  onChanged: (f) => ref
                      .read(claimMapNotifierProvider.notifier)
                      .setFilter(f),
                  showHeatMap: mapState.showHeatMap,
                  onToggleHeat: () => ref
                      .read(claimMapNotifierProvider.notifier)
                      .toggleHeatMap(),
                ),
              ],
            ),
          ),

          // ── Pin count badge ────────────────────────────────────────
          Positioned(
            top: 130,
            right: 12,
            child: _PinCountBadge(
              filter: mapState.activeFilter,
              ownCount: ownPins.length,
              friendCount: friendPins.length,
            ),
          ),

          // ── Bottom: pin detail + impact banner ─────────────────────
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mapState.selectedPin != null)
                  PinDetailSheet(
                    pin: mapState.selectedPin!,
                    onDismiss: () => ref
                        .read(claimMapNotifierProvider.notifier)
                        .clearPin(),
                  ),
                const SizedBox(height: 10),
                impactAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => stats != null
                      ? ImpactStatsBanner(stats: stats)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Heat loading indicator ─────────────────────────────────
          if (mapState.isLoadingHeat)
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                      Text('Loading heat zones...',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Pin Widget (drawn in Flutter, no BitmapDescriptor needed)
// ─────────────────────────────────────────────────────────────────────────────
class _PinWidget extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  final bool isSelected;

  const _PinWidget({
    required this.emoji,
    required this.color,
    required this.size,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(
          color: color,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isSelected ? 0.5 : 0.3),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.44),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets (same as before)
// ─────────────────────────────────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _PinCountBadge extends StatelessWidget {
  final MapFilter filter;
  final int ownCount;
  final int friendCount;
  const _PinCountBadge(
      {required this.filter,
        required this.ownCount,
        required this.friendCount});

  int get _count {
    switch (filter) {
      case MapFilter.mine:      return ownCount;
      case MapFilter.friends:   return friendCount;
      case MapFilter.all:
      case MapFilter.thisWeek:  return ownCount + friendCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text('$_count pins', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:trash/features/claim_map/data/providers/claim_map_providers.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Map UI State
// ─────────────────────────────────────────────────────────────────────────────
class ClaimMapState {
  final MapFilter activeFilter;
  final ClaimPin? selectedPin;
  final List<HeatZone> heatZones;
  final bool isLoadingHeat;
  final bool showHeatMap;
  final LatLng? lastCameraPosition;

  const ClaimMapState({
    this.activeFilter = MapFilter.mine,
    this.selectedPin,
    this.heatZones = const [],
    this.isLoadingHeat = false,
    this.showHeatMap = true,
    this.lastCameraPosition,
  });

  ClaimMapState copyWith({
    MapFilter? activeFilter,
    ClaimPin? selectedPin,
    List<HeatZone>? heatZones,
    bool? isLoadingHeat,
    bool? showHeatMap,
    LatLng? lastCameraPosition,
    bool clearPin = false,
  }) {
    return ClaimMapState(
      activeFilter: activeFilter ?? this.activeFilter,
      selectedPin: clearPin ? null : (selectedPin ?? this.selectedPin),
      heatZones: heatZones ?? this.heatZones,
      isLoadingHeat: isLoadingHeat ?? this.isLoadingHeat,
      showHeatMap: showHeatMap ?? this.showHeatMap,
      lastCameraPosition: lastCameraPosition ?? this.lastCameraPosition,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ClaimMap Notifier
// ─────────────────────────────────────────────────────────────────────────────
class ClaimMapNotifier extends Notifier<ClaimMapState> {
  @override
  ClaimMapState build() => const ClaimMapState();

  void setFilter(MapFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void selectPin(ClaimPin pin) {
    state = state.copyWith(selectedPin: pin);
  }

  void clearPin() {
    state = state.copyWith(clearPin: true);
  }

  void toggleHeatMap() {
    state = state.copyWith(showHeatMap: !state.showHeatMap);
  }

  void onCameraMove(LatLng position) {
    state = state.copyWith(lastCameraPosition: position);
  }

  Future<void> loadHeatZones({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    if (state.isLoadingHeat) return;
    state = state.copyWith(isLoadingHeat: true);

    final useCase = ref.read(getHeatZonesUseCaseProvider);
    final result = await useCase(
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
    );

    state = state.copyWith(
      isLoadingHeat: false,
      heatZones: result.zones,
    );
  }
}

final claimMapNotifierProvider =
    NotifierProvider<ClaimMapNotifier, ClaimMapState>(ClaimMapNotifier.new);

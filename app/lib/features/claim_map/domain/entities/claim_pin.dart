import 'package:trash/features/claiming/data/datasources/trash_label_map.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClaimPin – a single claim plotted on the map
// ─────────────────────────────────────────────────────────────────────────────
class ClaimPin {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final TrashCategory category;
  final DateTime claimedAt;
  final String? photoUrl;
  final bool isOwn;         // true = current user's pin (green)
  final bool isFriend;      // true = friend pin (blue)

  const ClaimPin({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.claimedAt,
    this.photoUrl,
    required this.isOwn,
    this.isFriend = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HeatZone – aggregated community claim density for a map tile
// ─────────────────────────────────────────────────────────────────────────────
class HeatZone {
  final double latitude;
  final double longitude;
  final int claimCount;   // total claims near this point
  final double radiusKm;

  const HeatZone({
    required this.latitude,
    required this.longitude,
    required this.claimCount,
    this.radiusKm = 0.3,
  });

  // Intensity 0.0–1.0 for heat map rendering
  double get intensity => (claimCount / 50).clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// MapFilter – controls what the map displays
// ─────────────────────────────────────────────────────────────────────────────
enum MapFilter { all, mine, friends, thisWeek }

extension MapFilterLabel on MapFilter {
  String get label {
    switch (this) {
      case MapFilter.all:
        return 'All';
      case MapFilter.mine:
        return 'Mine';
      case MapFilter.friends:
        return 'Friends';
      case MapFilter.thisWeek:
        return 'This Week';
    }
  }

  String get emoji {
    switch (this) {
      case MapFilter.all:
        return '🌍';
      case MapFilter.mine:
        return '📍';
      case MapFilter.friends:
        return '👥';
      case MapFilter.thisWeek:
        return '📅';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserImpactStats – "You helped clean X kg this month"
// ─────────────────────────────────────────────────────────────────────────────
class UserImpactStats {
  final int totalClaims;
  final int claimsThisMonth;
  final double estimatedKgCleaned;  // rough estimate: avg 0.1 kg per claim
  final int areasVisited;

  const UserImpactStats({
    required this.totalClaims,
    required this.claimsThisMonth,
    required this.estimatedKgCleaned,
    required this.areasVisited,
  });

  static UserImpactStats fromClaimCount({
    required int total,
    required int thisMonth,
    required int areas,
  }) {
    return UserImpactStats(
      totalClaims: total,
      claimsThisMonth: thisMonth,
      estimatedKgCleaned: thisMonth * 0.12,
      areasVisited: areas,
    );
  }
}

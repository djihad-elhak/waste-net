import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/profile/domain/entities/user_profile.dart';

// ── Repository interface ──────────────────────────────────────────────────────
abstract class ProfileRepository {
  Stream<UserProfile> watchProfile(String userId);
  Future<({bool success, Failure? failure})> updateProfile(
      ProfileEditData data, String userId);
  Future<void> signOut();
}

// ── Use Cases ─────────────────────────────────────────────────────────────────
class WatchProfileUseCase {
  final ProfileRepository _repo;
  const WatchProfileUseCase(this._repo);
  Stream<UserProfile> call(String userId) => _repo.watchProfile(userId);
}

class UpdateProfileUseCase {
  final ProfileRepository _repo;
  const UpdateProfileUseCase(this._repo);
  Future<({bool success, Failure? failure})> call(
          ProfileEditData data, String userId) =>
      _repo.updateProfile(data, userId);
}

class SignOutUseCase {
  final ProfileRepository _repo;
  const SignOutUseCase(this._repo);
  Future<void> call() => _repo.signOut();
}

// ── Datasource ────────────────────────────────────────────────────────────────
class ProfileDataSource {
  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  ProfileDataSource({FirebaseFirestore? db, fb.FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? fb.FirebaseAuth.instance;

  Stream<UserProfile> watchProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snap) {
      final d = snap.data() ?? {};
      final badges = _defaultBadges(d['totalClaims'] as int? ?? 0,
          d['streak'] as int? ?? 0, d['level'] as int? ?? 1);
      return UserProfile(
        uid: snap.id,
        firstName: d['firstName'] as String? ?? '',
        lastName: d['lastName'] as String? ?? '',
        username: d['username'] as String? ?? '',
        email: d['email'] as String? ?? '',
        photoUrl: d['photoUrl'] as String?,
        coins: d['coins'] as int? ?? 0,
        stars: d['stars'] as int? ?? 0,
        score: d['score'] as int? ?? 0,
        level: d['level'] as int? ?? 1,
        totalClaims: d['totalClaims'] as int? ?? 0,
        streak: d['streak'] as int? ?? 0,
        globalRank: d['globalRank'] as int? ?? 0,
        claimsByCategory: Map<String, int>.from(
            d['claimsByCategory'] as Map? ?? {}),
        badges: badges,
        joinedAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isEmailVerified: d['isEmailVerified'] as bool? ?? false,
      );
    });
  }

  List<TrashBadge > _defaultBadges(int claims, int streak, int level) {
    final badges = <TrashBadge >[];
    if (claims >= 1) {
      badges.add(TrashBadge(
          id: 'first_claim', name: 'First Claim', emoji: '🌱',
          description: 'Made your first claim', rarity: BadgeRarity.bronze,
          earnedAt: DateTime.now()));
    }
    if (claims >= 10) {
      badges.add(TrashBadge (
          id: 'ten_claims', name: 'Getting Started', emoji: '♻️',
          description: '10 total claims', rarity: BadgeRarity.bronze,
          earnedAt: DateTime.now()));
    }
    if (claims >= 50) {
      badges.add(TrashBadge (
          id: 'fifty_claims', name: 'Street Cleaner', emoji: '🧹',
          description: '50 total claims', rarity: BadgeRarity.silver,
          earnedAt: DateTime.now()));
    }
    if (claims >= 100) {
      badges.add(TrashBadge (
          id: 'hundred_claims', name: 'Eco Warrior', emoji: '⚔️',
          description: '100 total claims', rarity: BadgeRarity.gold,
          earnedAt: DateTime.now()));
    }
    if (streak >= 7) {
      badges.add(TrashBadge (
          id: 'week_streak', name: '7-Day Streak', emoji: '🔥',
          description: 'Claimed 7 days in a row', rarity: BadgeRarity.silver,
          earnedAt: DateTime.now()));
    }
    if (level >= 5) {
      badges.add(TrashBadge (
          id: 'level_5', name: 'Level 5', emoji: '⭐',
          description: 'Reached Level 5', rarity: BadgeRarity.gold,
          earnedAt: DateTime.now()));
    }
    if (level >= 10) {
      badges.add(TrashBadge (
          id: 'level_10', name: 'Legend', emoji: '👑',
          description: 'Reached Level 10', rarity: BadgeRarity.platinum,
          earnedAt: DateTime.now()));
    }
    return badges;
  }

  Future<({bool success, Failure? failure})> updateProfile(
      ProfileEditData data, String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'firstName': data.firstName.trim(),
        'lastName': data.lastName.trim(),
        'username': data.username.trim().toLowerCase(),
        if (data.photoUrl != null) 'photoUrl': data.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// ── Repository impl ───────────────────────────────────────────────────────────
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource _ds;
  const ProfileRepositoryImpl(this._ds);

  @override
  Stream<UserProfile> watchProfile(String userId) =>
      _ds.watchProfile(userId);
  @override
  Future<({bool success, Failure? failure})> updateProfile(
          ProfileEditData data, String userId) =>
      _ds.updateProfile(data, userId);
  @override
  Future<void> signOut() => _ds.signOut();
}

// ── Providers ─────────────────────────────────────────────────────────────────
final profileDataSourceProvider =
    Provider<ProfileDataSource>((_) => ProfileDataSource());

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepositoryImpl(ref.read(profileDataSourceProvider)));

final watchProfileUseCaseProvider = Provider(
    (ref) => WatchProfileUseCase(ref.read(profileRepositoryProvider)));
final updateProfileUseCaseProvider = Provider(
    (ref) => UpdateProfileUseCase(ref.read(profileRepositoryProvider)));
final profileSignOutUseCaseProvider = Provider(
    (ref) => SignOutUseCase(ref.read(profileRepositoryProvider)));

final userProfileProvider =
    StreamProvider.family<UserProfile, String>((ref, userId) =>
        ref.read(watchProfileUseCaseProvider).call(userId));

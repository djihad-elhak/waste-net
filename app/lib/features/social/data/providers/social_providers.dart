import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/social/data/datasources/social_datasource.dart';
import 'package:trash/features/social/domain/entities/social_entities.dart';
import 'package:trash/features/social/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SocialDataSource _ds;
  const SocialRepositoryImpl(this._ds);

  @override
  Stream<List<Friend>> watchFriends(String userId) =>
      _ds.watchFriends(userId);
  @override
  Future<({List<FeedItem> items, Failure? failure})> getFriendFeed(
          String userId) =>
      _ds.getFriendFeed(userId);
  @override
  Future<({List<LeaderboardEntry> entries, Failure? failure})> getLeaderboard({
    required String userId,
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? city,
  }) =>
      _ds.getLeaderboard(
          userId: userId, scope: scope, period: period, city: city);
  @override
  @override
  Future<({List<UserSearchResult> results, Failure? failure})> searchUsers({
    required String query,
    required String currentUserId,
  }) =>
      _ds.searchUsers(query: query, currentUserId: currentUserId);
  @override
  Future<({bool success, Failure? failure})> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) =>
      _ds.sendFriendRequest(
          fromUserId: fromUserId, toUserId: toUserId);
  @override
  Future<({bool success, Failure? failure})> acceptFriendRequest({
    required String userId,
    required String requesterId,
  }) =>
      _ds.acceptFriendRequest(
          userId: userId, requesterId: requesterId);
  @override
  Future<({bool success, Failure? failure})> removeFriend({
    required String userId,
    required String friendId,
  }) =>
      _ds.removeFriend(userId: userId, friendId: friendId);
}

// ── Providers ─────────────────────────────────────────────────────────────────
final socialDataSourceProvider =
    Provider<SocialDataSource>((_) => SocialDataSource());

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepositoryImpl(ref.read(socialDataSourceProvider)),
);

final watchFriendsUseCaseProvider = Provider(
    (ref) => WatchFriendsUseCase(ref.read(socialRepositoryProvider)));
final getFriendFeedUseCaseProvider = Provider(
    (ref) => GetFriendFeedUseCase(ref.read(socialRepositoryProvider)));
final getLeaderboardUseCaseProvider = Provider(
    (ref) => GetLeaderboardUseCase(ref.read(socialRepositoryProvider)));
final searchUsersUseCaseProvider = Provider(
    (ref) => SearchUsersUseCase(ref.read(socialRepositoryProvider)));
final sendFriendRequestUseCaseProvider = Provider(
    (ref) => SendFriendRequestUseCase(ref.read(socialRepositoryProvider)));
final removeFriendUseCaseProvider = Provider(
    (ref) => RemoveFriendUseCase(ref.read(socialRepositoryProvider)));

final friendsProvider =
    StreamProvider.family<List<Friend>, String>((ref, userId) =>
        ref.read(watchFriendsUseCaseProvider).call(userId));

final friendFeedProvider =
    FutureProvider.family<List<FeedItem>, String>((ref, userId) async {
  final r = await ref.read(getFriendFeedUseCaseProvider).call(userId);
  return r.items;
});

// Leaderboard family key
typedef LeaderboardKey = ({
  String userId,
  LeaderboardScope scope,
  LeaderboardPeriod period,
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>,
    LeaderboardKey>((ref, key) async {
  final r = await ref.read(getLeaderboardUseCaseProvider).call(
      userId: key.userId, scope: key.scope, period: key.period);
  return r.entries;
});

// Search state
final userSearchQueryProvider = StateProvider<String>((_) => '');
final userSearchResultsProvider =
    FutureProvider.family<List<UserSearchResult>, ({String query, String userId})>(
        (ref, params) async {
  if (params.query.length < 2) return [];
  final r = await ref.read(searchUsersUseCaseProvider).call(
      query: params.query, currentUserId: params.userId);
  return r.results;
});

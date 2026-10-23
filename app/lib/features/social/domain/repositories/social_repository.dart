import 'package:trash/core/error/failures.dart';
import 'package:trash/features/social/domain/entities/social_entities.dart';

// ── Repository ────────────────────────────────────────────────────────────────
abstract class SocialRepository {
  Stream<List<Friend>> watchFriends(String userId);
  Future<({List<FeedItem> items, Failure? failure})> getFriendFeed(String userId);
  Future<({List<LeaderboardEntry> entries, Failure? failure})> getLeaderboard({
    required String userId,
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? city,
  });
  Future<({List<UserSearchResult> results, Failure? failure})> searchUsers({
    required String query,
    required String currentUserId,
  });
  Future<({bool success, Failure? failure})> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  });
  Future<({bool success, Failure? failure})> acceptFriendRequest({
    required String userId,
    required String requesterId,
  });
  Future<({bool success, Failure? failure})> removeFriend({
    required String userId,
    required String friendId,
  });
}

// ── Use Cases ─────────────────────────────────────────────────────────────────
class WatchFriendsUseCase {
  final SocialRepository _repo;
  const WatchFriendsUseCase(this._repo);
  Stream<List<Friend>> call(String userId) => _repo.watchFriends(userId);
}

class GetFriendFeedUseCase {
  final SocialRepository _repo;
  const GetFriendFeedUseCase(this._repo);
  Future<({List<FeedItem> items, Failure? failure})> call(String userId) =>
      _repo.getFriendFeed(userId);
}

class GetLeaderboardUseCase {
  final SocialRepository _repo;
  const GetLeaderboardUseCase(this._repo);
  Future<({List<LeaderboardEntry> entries, Failure? failure})> call({
    required String userId,
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? city,
  }) =>
      _repo.getLeaderboard(
          userId: userId, scope: scope, period: period, city: city);
}

class SearchUsersUseCase {
  final SocialRepository _repo;
  const SearchUsersUseCase(this._repo);
  Future<({List<UserSearchResult> results, Failure? failure})> call({
    required String query,
    required String currentUserId,
  }) =>
      _repo.searchUsers(query: query, currentUserId: currentUserId);
}

class SendFriendRequestUseCase {
  final SocialRepository _repo;
  const SendFriendRequestUseCase(this._repo);
  Future<({bool success, Failure? failure})> call({
    required String fromUserId,
    required String toUserId,
  }) =>
      _repo.sendFriendRequest(
          fromUserId: fromUserId, toUserId: toUserId);
}

class RemoveFriendUseCase {
  final SocialRepository _repo;
  const RemoveFriendUseCase(this._repo);
  Future<({bool success, Failure? failure})> call({
    required String userId,
    required String friendId,
  }) =>
      _repo.removeFriend(userId: userId, friendId: friendId);
}

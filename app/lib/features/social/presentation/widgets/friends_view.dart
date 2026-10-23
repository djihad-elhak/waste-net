import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/social/data/providers/social_providers.dart';
import 'package:trash/features/social/domain/entities/social_entities.dart';
import 'package:trash/features/social/presentation/controllers/social_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Friends Tab
// ─────────────────────────────────────────────────────────────────────────────
class FriendsView extends ConsumerWidget {
  final String userId;
  const FriendsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider(userId));
    final feedAsync = ref.watch(friendFeedProvider(userId));
    final query = ref.watch(userSearchQueryProvider);
    final searchAsync = query.length >= 2
        ? ref.watch(userSearchResultsProvider(
            (query: query, userId: userId)))
        : null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Search bar ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchBar(userId: userId),
          ),
        ),

        // ── Search results ─────────────────────────────────────────────
        if (query.length >= 2 && searchAsync != null)
          SliverToBoxAdapter(
            child: searchAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (results) => _SearchResults(
                  results: results, userId: userId),
            ),
          )
        else ...[
          // ── Friends list ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: friendsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (friends) => _FriendsSection(
                    friends: friends, userId: userId),
              ),
            ),
          ),

          // ── Activity feed ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: feedAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (feed) => _ActivityFeed(feed: feed),
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends ConsumerWidget {
  final String userId;
  const _SearchBar({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (v) =>
          ref.read(userSearchQueryProvider.notifier).state = v,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search by username...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: ref.watch(userSearchQueryProvider).isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () =>
                    ref.read(userSearchQueryProvider.notifier).state = '',
              )
            : null,
      ),
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────────
class _SearchResults extends ConsumerWidget {
  final List<UserSearchResult> results;
  final String userId;

  const _SearchResults({required this.results, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('No users found', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Results', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 10),
          ...results.map((r) => _SearchResultRow(
              result: r, currentUserId: userId)),
        ],
      ),
    );
  }
}

class _SearchResultRow extends ConsumerWidget {
  final UserSearchResult result;
  final String currentUserId;

  const _SearchResultRow(
      {required this.result, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(socialControllerProvider);
    final isLoading = actionState.loadingUids.contains(result.uid);
    final sentRequest = actionState.sentRequestUids.contains(result.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _MiniAvatar(
            photoUrl: result.photoUrl,
            letter: result.firstName.isNotEmpty
                ? result.firstName[0].toUpperCase()
                : '?',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${result.username}',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Level ${result.level}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          if (result.isFriend)
            _PillChip(label: 'Friends ✓', color: AppColors.accentGreen)
          else if (sentRequest || result.hasRequestPending)
            _PillChip(label: 'Sent', color: AppColors.textHint)
          else
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      ref.read(socialControllerProvider.notifier).sendRequest(
                            fromUserId: currentUserId,
                            toUserId: result.uid,
                          );
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Friends Section ───────────────────────────────────────────────────────────
class _FriendsSection extends ConsumerWidget {
  final List<Friend> friends;
  final String userId;

  const _FriendsSection({required this.friends, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Friends', style: AppTextStyles.headlineMedium),
            const SizedBox(width: 8),
            _PillChip(
                label: '${friends.length}',
                color: AppColors.accentGreen),
          ],
        ),
        const SizedBox(height: 10),
        if (friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Text('👥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No friends yet',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('Search by username to add friends',
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...friends.map((f) => _FriendRow(friend: f, userId: userId)),
      ],
    );
  }
}

class _FriendRow extends ConsumerWidget {
  final Friend friend;
  final String userId;

  const _FriendRow({required this.friend, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _MiniAvatar(
            photoUrl: friend.photoUrl,
            letter: friend.firstName.isNotEmpty
                ? friend.firstName[0].toUpperCase()
                : '?',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${friend.username}',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                Row(
                  children: [
                    Text('Lv.${friend.level}',
                        style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Text('${friend.totalClaims} claims',
                        style: AppTextStyles.caption),
                    if (friend.streak >= 3) ...[
                      const SizedBox(width: 6),
                      const Text('🔥',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text('🪙 ${friend.coins}',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── Activity Feed ─────────────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  final List<FeedItem> feed;
  const _ActivityFeed({required this.feed});

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Activity', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 10),
        ...feed.map((item) => _FeedCard(item: item)),
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  const _FeedCard({required this.item});

  String get _message {
    switch (item.type) {
      case FeedItemType.claim:
        return 'just claimed ${item.claimCount > 1 ? '${item.claimCount} ${item.categoryDisplayName} items' : 'a ${item.categoryDisplayName}'}';
      case FeedItemType.levelUp:
        return 'levelled up! 🎉';
      case FeedItemType.missionComplete:
        return 'completed a mission';
      case FeedItemType.streak:
        return 'is on a streak 🔥';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniAvatar(
            photoUrl: item.photoUrl,
            letter: item.firstName.isNotEmpty
                ? item.firstName[0].toUpperCase()
                : '?',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                    children: [
                      TextSpan(
                        text: item.firstName.isNotEmpty
                            ? item.firstName
                            : item.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' $_message'),
                    ],
                  ),
                ),
                if (item.coinsEarned > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '+ 🪙 ${item.coinsEarned} coins',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(item.timeAgo, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _MiniAvatar extends StatelessWidget {
  final String? photoUrl;
  final String letter;
  const _MiniAvatar({this.photoUrl, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: photoUrl != null
          ? ClipOval(
              child: Image.network(photoUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(letter,
                          style: const TextStyle(
                              color: AppColors.accentGreen,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)))))
          : Center(
              child: Text(letter,
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ))),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

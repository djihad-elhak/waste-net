import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/social/data/providers/social_providers.dart';
import 'package:trash/features/social/domain/entities/social_entities.dart';
import 'package:trash/features/social/presentation/controllers/social_controller.dart';

class LeaderboardView extends ConsumerWidget {
  final String userId;
  const LeaderboardView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(leaderboardScopeProvider);
    final period = ref.watch(leaderboardPeriodProvider);
    final key = (userId: userId, scope: scope, period: period);
    final boardAsync = ref.watch(leaderboardProvider(key));

    return Column(
      children: [
        // ── Scope + Period toggles ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _ToggleRow<LeaderboardScope>(
                options: LeaderboardScope.values,
                selected: scope,
                label: (s) => switch (s) {
                  LeaderboardScope.global  => '🌍 Global',
                  LeaderboardScope.local   => '🏙️ Local',
                  LeaderboardScope.friends => '👥 Friends',
                },
                onSelect: (s) {
                  HapticFeedback.selectionClick();
                  ref.read(leaderboardScopeProvider.notifier).state = s;
                },
              ),
              const SizedBox(height: 8),
              _ToggleRow<LeaderboardPeriod>(
                options: LeaderboardPeriod.values,
                selected: period,
                label: (p) => switch (p) {
                  LeaderboardPeriod.weekly  => 'This Week',
                  LeaderboardPeriod.allTime => 'All Time',
                },
                onSelect: (p) {
                  HapticFeedback.selectionClick();
                  ref.read(leaderboardPeriodProvider.notifier).state = p;
                },
              ),
            ],
          ),
        ),

        // ── List ──────────────────────────────────────────────────────
        Expanded(
          child: boardAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
              ),
            ),
            error: (_, __) => const Center(child: Text('Failed to load')),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Text('No data yet', style: AppTextStyles.bodyMedium),
                );
              }

              final top3 = entries.take(3).toList();
              final rest = entries.skip(3).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Podium
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _Podium(top3: top3),
                    ),
                  ),

                  // Ranked list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _RankRow(entry: rest[i]),
                        childCount: rest.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Toggle Row ────────────────────────────────────────────────────────────────
class _ToggleRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: options.map((o) {
          final isSelected = o == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    label(o),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final first  = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third  = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepGreen.withOpacity(0.8),
            AppColors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) _PodiumSlot(entry: second, height: 90, medal: '🥈'),
          const SizedBox(width: 8),
          if (first != null) _PodiumSlot(entry: first, height: 120, medal: '🥇'),
          const SizedBox(width: 8),
          if (third != null) _PodiumSlot(entry: third, height: 70, medal: '🥉'),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final String medal;

  const _PodiumSlot(
      {required this.entry, required this.height, required this.medal});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          _UserAvatar(
            photoUrl: entry.photoUrl,
            letter: entry.firstName.isNotEmpty
                ? entry.firstName[0].toUpperCase()
                : '?',
            size: 44,
            highlight: isMe,
          ),
          const SizedBox(height: 6),
          Text(
            isMe ? 'You' : entry.username,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isMe ? AppColors.accentGreen : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${_formatNum(entry.score)} pts',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          // Podium block
          Container(
            height: height,
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.accentGreen.withOpacity(0.15)
                  : AppColors.divider,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
              border: Border.all(
                color: isMe
                    ? AppColors.accentGreen.withOpacity(0.4)
                    : AppColors.cardBorder,
              ),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isMe ? AppColors.accentGreen : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Rank Row ──────────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.accentGreen.withOpacity(0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.accentGreen.withOpacity(0.35)
              : AppColors.cardBorder,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.accentGreen : AppColors.textSecondary,
              ),
            ),
          ),
          // Avatar
          _UserAvatar(
            photoUrl: entry.photoUrl,
            letter: entry.firstName.isNotEmpty
                ? entry.firstName[0].toUpperCase()
                : '?',
            size: 36,
            highlight: isMe,
          ),
          const SizedBox(width: 10),
          // Name + claims
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You' : '@${entry.username}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isMe
                        ? AppColors.accentGreen
                        : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${entry.totalClaims} claims · Lv.${entry.level}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNum(entry.score),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isMe ? AppColors.accentGreen : AppColors.textPrimary,
                ),
              ),
              Text('pts', style: AppTextStyles.caption),
            ],
          ),
          if (entry.streak >= 3) ...[
            const SizedBox(width: 8),
            Text('🔥', style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Avatar helper ─────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String letter;
  final double size;
  final bool highlight;

  const _UserAvatar({
    this.photoUrl,
    required this.letter,
    required this.size,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(
          color: highlight
              ? AppColors.accentGreen
              : AppColors.cardBorder,
          width: highlight ? 2 : 1,
        ),
      ),
      child: photoUrl != null
          ? ClipOval(
              child: Image.network(photoUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Center(child: Text(letter,
                          style: TextStyle(
                              color: AppColors.accentGreen,
                              fontFamily: 'Poppins',
                              fontSize: size * 0.38,
                              fontWeight: FontWeight.w700)))))
          : Center(
              child: Text(letter,
                  style: TextStyle(
                    color: AppColors.accentGreen,
                    fontFamily: 'Poppins',
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w700,
                  ))),
    );
  }
}

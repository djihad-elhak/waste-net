import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/home/data/providers/home_providers.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';
import 'package:trash/features/home/presentation/widgets/greeting_header.dart';
import 'package:trash/features/home/presentation/widgets/level_progress_bar.dart';
import 'package:trash/features/home/presentation/widgets/missions_preview.dart';
import 'package:trash/features/home/presentation/widgets/rewards_carousel.dart';
import 'package:trash/features/home/presentation/widgets/stats_row.dart';

import 'package:trash/features/auth/data/providers/auth_providers.dart'; // ADD at top of file with other imports

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    final statsAsync = ref.watch(userStatsProvider(userId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: statsAsync.when(
          loading: () => const _HomeSkeletonLoader(),
          error: (e, _) => _HomeError(onRetry: () => ref.invalidate(userStatsProvider(userId))),
          data: (stats) => _HomeBody(stats: stats, userId: userId),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main scrollable body
// ─────────────────────────────────────────────────────────────────────────────
class _HomeBody extends ConsumerWidget {
  final UserStats stats;

  final String userId;                                         // ← ADD this field
  const _HomeBody({required this.stats, required this.userId}); // ← ADD userId param


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(dailyMissionsProvider(userId));
    final rewardsAsync = ref.watch(availableRewardsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Pinned top section (header + currency bar) ─────────────────────
        SliverToBoxAdapter(
          child: _HomeTopSection(stats: stats),
        ),

        // ── Scrollable content ─────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Level XP bar
              const SizedBox(height: 20),
              LevelProgressBar(stats: stats),

              // Stats row
              const SizedBox(height: 20),
              StatsRow(stats: stats),

              // Rewards carousel
              const SizedBox(height: 28),
              rewardsAsync.when(
                loading: () => const _SectionSkeleton(height: 160),
                error: (_, __) => const SizedBox.shrink(),
                data: (rewards) => RewardsCarousel(
                  rewards: rewards,
                  userCoins: stats.coins,
                  userId: userId,
                ),
              ),

              // Today's missions
              const SizedBox(height: 28),
              missionsAsync.when(
                loading: () => const _SectionSkeleton(height: 180),
                error: (_, __) => const SizedBox.shrink(),
                data: (missions) => MissionsPreview(
                  missions: missions,
                  onViewAll: () => context.go(AppConstants.routeMissions),
                ),
              ),

              const SizedBox(height: 12),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top section – header + currency tray
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTopSection extends StatelessWidget {
  final UserStats stats;

  const _HomeTopSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepGreen.withOpacity(0.95),
            AppColors.background,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Greeting header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GreetingHeader(stats: stats),
            ),

            const SizedBox(height: 16),

            // Currency tray
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CurrencyTray(stats: stats),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency Tray – coins / stars / score in a dark pill row
// ─────────────────────────────────────────────────────────────────────────────
class _CurrencyTray extends StatelessWidget {
  final UserStats stats;

  const _CurrencyTray({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CurrencyCell(
              emoji: '🪙',
              value: _formatNumber(stats.coins),
              label: 'Coins',
              color: const Color(0xFFFFD700),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.cardBorder),
          Expanded(
            child: _CurrencyCell(
              emoji: '⭐',
              value: _formatNumber(stats.stars),
              label: 'Stars',
              color: const Color(0xFF7C6CFF),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.cardBorder),
          Expanded(
            child: _CurrencyCell(
              emoji: '⚡',
              value: _formatNumber(stats.score),
              label: 'Score',
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _CurrencyCell extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _CurrencyCell({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loader
// ─────────────────────────────────────────────────────────────────────────────
class _HomeSkeletonLoader extends StatefulWidget {
  const _HomeSkeletonLoader();

  @override
  State<_HomeSkeletonLoader> createState() => _HomeSkeletonLoaderState();
}

class _HomeSkeletonLoaderState extends State<_HomeSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 180, height: 28, opacity: _anim.value),
              const SizedBox(height: 8),
              _Bone(width: 120, height: 16, opacity: _anim.value * 0.7),
              const SizedBox(height: 24),
              _Bone(width: double.infinity, height: 60, opacity: _anim.value),
              const SizedBox(height: 16),
              _Bone(width: double.infinity, height: 12, opacity: _anim.value),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _Bone(width: double.infinity, height: 80, opacity: _anim.value)),
                const SizedBox(width: 12),
                Expanded(child: _Bone(width: double.infinity, height: 80, opacity: _anim.value)),
                const SizedBox(width: 12),
                Expanded(child: _Bone(width: double.infinity, height: 80, opacity: _anim.value)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _Bone(
      {required this.width, required this.height, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(opacity),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final double height;
  const _SectionSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────
class _HomeError extends StatelessWidget {
  final VoidCallback onRetry;
  const _HomeError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌐', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Failed to load dashboard', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

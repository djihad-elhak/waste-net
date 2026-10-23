import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/features/missions/data/providers/missions_providers.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';
import 'package:trash/features/missions/presentation/controllers/missions_controller.dart';
import 'package:trash/features/missions/presentation/widgets/mission_card.dart';
import 'package:trash/features/missions/presentation/widgets/mission_claimed_overlay.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = [
    (label: 'All', type: null),
    (label: '☀️ Daily', type: MissionType.daily),
    (label: '📅 Weekly', type: MissionType.weekly),
    (label: '⚡ Special', type: MissionType.special),
    (label: '🌿 Seasonal', type: MissionType.seasonal),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);

    // Seed missions on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user   = ref.read(authStateProvider).valueOrNull;
      final userId = user?.uid ?? '';
      ref.read(seedMissionsUseCaseProvider).call(userId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    final missionsAsync = ref.watch(missionsProvider(userId));    // was _mockUserId
    final claimState    = ref.watch(missionsControllerProvider);

    // Show claimed overlay when a mission is successfully claimed
    Mission? justClaimed;
    if (claimState.successMissionId != null) {
      justClaimed = missionsAsync.valueOrNull?.firstWhere(
        (m) => m.id == claimState.successMissionId,
        orElse: () => _placeholderMission(claimState.successMissionId!),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Main content ─────────────────────────────────────────────
            NestedScrollView(
              headerSliverBuilder: (context, _) => [
                _MissionsAppBar(tabCtrl: _tabCtrl, tabs: _tabs),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: _tabs.map((tab) {
                  return missionsAsync.when(
                    loading: () => const _MissionsLoader(),
                    error: (e, _) => _MissionsError(
                      onRetry: () => ref.invalidate(
                          missionsProvider(userId)),
                    ),
                    data: (missions) {
                      final filtered = tab.type == null
                          ? missions
                          : missions
                              .where((m) => m.type == tab.type)
                              .toList();
                      return _MissionsList(
                        missions: filtered,
                        userId: userId,
                        filterType: tab.type,
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            // ── Claimed overlay ───────────────────────────────────────────
            if (justClaimed != null)
              MissionClaimedOverlay(
                mission: justClaimed,
                onDismiss: () {
                  ref
                      .read(missionsControllerProvider.notifier)
                      .clearSuccess();
                },
              ),
          ],
        ),
      ),
    );
  }

  Mission _placeholderMission(String id) => Mission(
        id: id,
        title: 'Mission Complete',
        description: '',
        emoji: '🎯',
        type: MissionType.daily,
        status: MissionStatus.claimed,
        difficulty: MissionDifficulty.easy,
        targetCount: 1,
        currentCount: 1,
        rewardCoins: 50,
        rewardStars: 1,
        rewardScore: 10,
        expiresAt: DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar with tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _MissionsAppBar extends StatelessWidget {
  final TabController tabCtrl;
  final List<({String label, MissionType? type})> tabs;

  const _MissionsAppBar({required this.tabCtrl, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Missions', style: AppTextStyles.headlineLarge),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.deepGreen.withOpacity(0.6),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          color: AppColors.background,
          child: TabBar(
            controller: tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: AppColors.accentGreen,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            labelColor: AppColors.accentGreen,
            unselectedLabelColor: AppColors.textHint,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: tabs
                .map((t) => Tab(text: t.label))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Missions list
// ─────────────────────────────────────────────────────────────────────────────
class _MissionsList extends StatelessWidget {
  final List<Mission> missions;
  final String userId;
  final MissionType? filterType;

  const _MissionsList({
    required this.missions,
    required this.userId,
    this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return _EmptyState(type: filterType);
    }

    // Group by status
    final active = missions.where((m) => m.status == MissionStatus.active).toList();
    final completed = missions.where((m) => m.status == MissionStatus.completed).toList();
    final claimed = missions.where((m) => m.status == MissionStatus.claimed).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Summary bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SummaryBar(missions: missions),
          ),
        ),

        // Active missions
        if (active.isNotEmpty) ...[
          _SectionHeader(
              title: 'In Progress', count: active.length, color: AppColors.accentGreen),
          _MissionSliver(missions: active, userId: userId),
        ],

        // Completed – ready to claim
        if (completed.isNotEmpty) ...[
          _SectionHeader(
              title: 'Ready to Claim!',
              count: completed.length,
              color: const Color(0xFFFFD700)),
          _MissionSliver(missions: completed, userId: userId),
        ],

        // Already claimed
        if (claimed.isNotEmpty) ...[
          _SectionHeader(
              title: 'Completed',
              count: claimed.length,
              color: AppColors.textHint),
          _MissionSliver(missions: claimed, userId: userId),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 15,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionSliver extends StatelessWidget {
  final List<Mission> missions;
  final String userId;

  const _MissionSliver({required this.missions, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MissionCard(mission: missions[i], userId: userId),
          ),
          childCount: missions.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary bar – overall progress
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final List<Mission> missions;

  const _SummaryBar({required this.missions});

  @override
  Widget build(BuildContext context) {
    final total = missions.length;
    final done = missions.where((m) => m.isCompleted).length;
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done / $total missions done',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accentGreen),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Loading / Error states
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final MissionType? type;
  const _EmptyState({this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type?.emoji ?? '🎯',
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 16),
          Text(
            type != null
                ? 'No ${type!.label} missions right now'
                : 'No missions available yet',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon!',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _MissionsLoader extends StatelessWidget {
  const _MissionsLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
      ),
    );
  }
}

class _MissionsError extends StatelessWidget {
  final VoidCallback onRetry;
  const _MissionsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Failed to load missions', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/features/social/presentation/controllers/social_controller.dart';
import 'package:trash/features/social/presentation/widgets/friends_view.dart';
import 'package:trash/features/social/presentation/widgets/leaderboard_view.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      ref.read(socialTabProvider.notifier).state = _tabCtrl.index;
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
    return AnnotatedRegion<SystemUiOverlayStyle>
      (
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              expandedHeight: 110,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 52),
                title: Text('Social', style: AppTextStyles.headlineLarge),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.deepGreen.withOpacity(0.5),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: Container(
                  color: AppColors.background,
                  child: TabBar(
                    controller: _tabCtrl,
                    dividerColor: Colors.transparent,
                    indicatorColor: AppColors.accentGreen,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    labelColor: AppColors.accentGreen,
                    unselectedLabelColor: AppColors.textHint,
                    tabs: const [
                      Tab(text: '👥 Friends'),
                      Tab(text: '🏆 Leaderboard'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              FriendsView(userId: userId),
              LeaderboardView(userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

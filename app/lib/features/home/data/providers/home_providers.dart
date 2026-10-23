import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/home/data/datasources/home_datasource.dart';
import 'package:trash/features/home/data/repositories/home_repository_impl.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';
import 'package:trash/features/home/domain/repositories/home_repository.dart';
import 'package:trash/features/home/domain/usecases/home_usecases.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final homeDataSourceProvider = Provider<HomeDataSource>((_) => HomeDataSource());

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.read(homeDataSourceProvider)),
);

// ── Use Cases ─────────────────────────────────────────────────────────────
final watchUserStatsUseCaseProvider = Provider(
  (ref) => WatchUserStatsUseCase(ref.read(homeRepositoryProvider)),
);

final getDailyMissionsUseCaseProvider = Provider(
  (ref) => GetDailyMissionsUseCase(ref.read(homeRepositoryProvider)),
);

final getAvailableRewardsUseCaseProvider = Provider(
  (ref) => GetAvailableRewardsUseCase(ref.read(homeRepositoryProvider)),
);

final redeemRewardUseCaseProvider = Provider(
  (ref) => RedeemRewardUseCase(ref.read(homeRepositoryProvider)),
);

// ── Live user stats stream ────────────────────────────────────────────────
// Pass the userId from your auth provider
final userStatsProvider =
    StreamProvider.family<UserStats, String>((ref, userId) {
  return ref.read(watchUserStatsUseCaseProvider).call(userId);
});

// ── Daily missions ────────────────────────────────────────────────────────
final dailyMissionsProvider =
    FutureProvider.family<List<MissionPreview>, String>((ref, userId) async {
  final result =
      await ref.read(getDailyMissionsUseCaseProvider).call(userId);
  return result.missions;
});

// ── Available rewards ─────────────────────────────────────────────────────
final availableRewardsProvider =
    FutureProvider<List<RewardItem>>((ref) async {
  final result = await ref.read(getAvailableRewardsUseCaseProvider).call();
  return result.rewards;
});

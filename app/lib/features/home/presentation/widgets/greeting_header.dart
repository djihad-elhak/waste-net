import 'package:flutter/material.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';

class GreetingHeader extends StatelessWidget {
  final UserStats stats;

  const GreetingHeader({super.key, required this.stats});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        _Avatar(photoUrl: stats.photoUrl, firstName: stats.firstName),

        const SizedBox(width: 14),

        // Greeting + name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                stats.firstName.isNotEmpty ? stats.firstName : stats.username,
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Right side: level badge + streak
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _LevelBadge(level: stats.level),
            const SizedBox(height: 6),
            if (stats.streak > 0) _StreakBadge(streak: stats.streak),
          ],
        ),
      ],
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String firstName;

  const _Avatar({this.photoUrl, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: photoUrl != null
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(firstName: firstName),
              ),
            )
          : _Initials(firstName: firstName),
    );
  }
}

class _Initials extends StatelessWidget {
  final String firstName;
  const _Initials({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
        style: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.accentGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Level Badge ──────────────────────────────────────────────────────────────
class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.glowGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✦', style: TextStyle(fontSize: 10, color: Colors.white)),
          const SizedBox(width: 4),
          Text(
            'Lv.$level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Badge ─────────────────────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

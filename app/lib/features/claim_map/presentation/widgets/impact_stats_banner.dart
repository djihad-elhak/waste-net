import 'package:flutter/material.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';

class ImpactStatsBanner extends StatelessWidget {
  final UserImpactStats stats;

  const ImpactStatsBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ImpactItem(
            emoji: '♻️',
            value: '${stats.estimatedKgCleaned.toStringAsFixed(1)} kg',
            label: 'Cleaned',
          ),
          _Divider(),
          _ImpactItem(
            emoji: '📸',
            value: stats.claimsThisMonth.toString(),
            label: 'This month',
          ),
          _Divider(),
          _ImpactItem(
            emoji: '🗺️',
            value: stats.areasVisited.toString(),
            label: 'Areas',
          ),
          _Divider(),
          _ImpactItem(
            emoji: '🏆',
            value: stats.totalClaims.toString(),
            label: 'Total',
          ),
        ],
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _ImpactItem({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accentGreen,
            fontSize: 14,
          ),
        ),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.cardBorder);
  }
}

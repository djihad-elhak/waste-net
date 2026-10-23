import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';

class PinDetailSheet extends StatelessWidget {
  final ClaimPin pin;
  final VoidCallback onDismiss;

  const PinDetailSheet({
    super.key,
    required this.pin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final pinColor = pin.isOwn
        ? AppColors.accentGreen
        : const Color(0xFF4D9FFF);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pinColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Emoji circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pinColor.withOpacity(0.12),
                        border: Border.all(
                            color: pinColor.withOpacity(0.3), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          pin.category.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Title + owner
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pin.category.displayName,
                            style: AppTextStyles.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: pinColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pin.isOwn
                                    ? 'Your claim'
                                    : 'Friend\'s claim',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: pinColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Dismiss
                    GestureDetector(
                      onTap: onDismiss,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Details grid
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: DateFormat('MMM d, y').format(pin.claimedAt),
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: DateFormat('HH:mm').format(pin.claimedAt),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.location_on_rounded,
                        label: 'Coordinates',
                        value:
                            '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.star_rounded,
                        label: 'Rarity',
                        value: pin.category.rarityLabel,
                        valueColor: pin.category.rarityColor,
                      ),
                    ),
                  ],
                ),

                // Photo preview (if available)
                if (pin.photoUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      pin.photoUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: AppColors.card,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.textHint),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

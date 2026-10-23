import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';

class MapFilterBar extends StatelessWidget {
  final MapFilter active;
  final ValueChanged<MapFilter> onChanged;
  final bool showHeatMap;
  final VoidCallback onToggleHeat;

  const MapFilterBar({
    super.key,
    required this.active,
    required this.onChanged,
    required this.showHeatMap,
    required this.onToggleHeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: MapFilter.values.map((f) {
                  final isActive = active == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      filter: f,
                      isActive: isActive,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Heat map toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleHeat();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: showHeatMap
                    ? AppColors.orange.withOpacity(0.15)
                    : AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: showHeatMap
                      ? AppColors.orange.withOpacity(0.5)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔥',
                    style: TextStyle(
                      fontSize: 13,
                      color: showHeatMap
                          ? AppColors.orange
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Heat',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: showHeatMap
                          ? AppColors.orange
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final MapFilter filter;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  Color get _activeColor {
    switch (filter) {
      case MapFilter.mine:
        return AppColors.accentGreen;
      case MapFilter.friends:
        return const Color(0xFF4D9FFF);
      case MapFilter.thisWeek:
        return const Color(0xFF7C6CFF);
      case MapFilter.all:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? _activeColor.withOpacity(0.15)
              : AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? _activeColor.withOpacity(0.5)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(filter.emoji,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              filter.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrashLabelMap
//
// Maps your DenseNet model's output class indices → TrashCategory objects.
// ORDER must match your model's training class order exactly.
// If your model uses different class names, update the `modelKey` fields.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

enum TrashRarity { common, uncommon, rare, epic }

class TrashCategory {
  final int classIndex;
  final String modelKey;       // Label as exported from model training
  final String displayName;    // Shown to user
  final String emoji;
  final int baseCoins;
  final int baseScore;
  final int baseStars;
  final TrashRarity rarity;
  final Color color;

  const TrashCategory({
    required this.classIndex,
    required this.modelKey,
    required this.displayName,
    required this.emoji,
    required this.baseCoins,
    required this.baseScore,
    required this.baseStars,
    required this.rarity,
    required this.color,
  });

  String get rarityLabel {
    switch (rarity) {
      case TrashRarity.common:
        return 'Common';
      case TrashRarity.uncommon:
        return 'Uncommon';
      case TrashRarity.rare:
        return 'Rare';
      case TrashRarity.epic:
        return 'Epic';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case TrashRarity.common:
        return const Color(0xFF8BAF99);
      case TrashRarity.uncommon:
        return const Color(0xFF1FD47A);
      case TrashRarity.rare:
        return const Color(0xFF4D9FFF);
      case TrashRarity.epic:
        return const Color(0xFFB46EFF);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full label map — 12 categories
// Adjust classIndex order to match your DenseNet output layer.
// ─────────────────────────────────────────────────────────────────────────────
class TrashLabelMap {
  static const List<TrashCategory> categories = [
    TrashCategory(
      classIndex: 0,
      modelKey: 'cardboard',
      displayName: 'Cardboard',
      emoji: '📦',
      baseCoins: 25,
      baseScore: 8,
      baseStars: 1,
      rarity: TrashRarity.common,
      color: Color(0xFFB07C4F),
    ),
    TrashCategory(
      classIndex: 1,
      modelKey: 'carton_milk',
      displayName: 'Milk Carton',
      emoji: '🥛',
      baseCoins: 30,
      baseScore: 10,
      baseStars: 1,
      rarity: TrashRarity.common,
      color: Color(0xFFE8E8E8),
    ),
    TrashCategory(
      classIndex: 2,
      modelKey: 'glass',
      displayName: 'Glass Bottle',
      emoji: '🍾',
      baseCoins: 45,
      baseScore: 14,
      baseStars: 2,
      rarity: TrashRarity.uncommon,
      color: Color(0xFF5BA85A),
    ),
    TrashCategory(
      classIndex: 3,
      modelKey: 'metal_can',
      displayName: 'Metal Can',
      emoji: '🥫',
      baseCoins: 40,
      baseScore: 12,
      baseStars: 2,
      rarity: TrashRarity.uncommon,
      color: Color(0xFFADB5BD),
    ),
    TrashCategory(
      classIndex: 4,
      modelKey: 'organic',
      displayName: 'Organic Waste',
      emoji: '🍂',
      baseCoins: 20,
      baseScore: 6,
      baseStars: 1,
      rarity: TrashRarity.common,
      color: Color(0xFF7A5C3A),
    ),
    TrashCategory(
      classIndex: 5,
      modelKey: 'paper',
      displayName: 'Paper',
      emoji: '📄',
      baseCoins: 22,
      baseScore: 7,
      baseStars: 1,
      rarity: TrashRarity.common,
      color: Color(0xFFF5F0E8),
    ),
    TrashCategory(
      classIndex: 6,
      modelKey: 'plastic_bag',
      displayName: 'Plastic Bag',
      emoji: '🛍️',
      baseCoins: 50,
      baseScore: 16,
      baseStars: 2,
      rarity: TrashRarity.uncommon,
      color: Color(0xFF7EC8E3),
    ),
    TrashCategory(
      classIndex: 7,
      modelKey: 'plastic_bottle',
      displayName: 'Plastic Bottle',
      emoji: '🍶',
      baseCoins: 35,
      baseScore: 11,
      baseStars: 1,
      rarity: TrashRarity.common,
      color: Color(0xFF00B4D8),
    ),
    TrashCategory(
      classIndex: 8,
      modelKey: 'plastic_other',
      displayName: 'Plastic Waste',
      emoji: '♻️',
      baseCoins: 55,
      baseScore: 18,
      baseStars: 2,
      rarity: TrashRarity.rare,
      color: Color(0xFF4D9FFF),
    ),
    TrashCategory(
      classIndex: 9,
      modelKey: 'cigarette',
      displayName: 'Cigarette Butt',
      emoji: '🚬',
      baseCoins: 60,
      baseScore: 20,
      baseStars: 3,
      rarity: TrashRarity.rare,
      color: Color(0xFFFF8C52),
    ),
    TrashCategory(
      classIndex: 10,
      modelKey: 'electronics',
      displayName: 'E-Waste',
      emoji: '📱',
      baseCoins: 80,
      baseScore: 28,
      baseStars: 3,
      rarity: TrashRarity.epic,
      color: Color(0xFFB46EFF),
    ),
    TrashCategory(
      classIndex: 11,
      modelKey: 'hazardous',
      displayName: 'Hazardous Waste',
      emoji: '⚠️',
      baseCoins: 100,
      baseScore: 35,
      baseStars: 4,
      rarity: TrashRarity.epic,
      color: Color(0xFFFF4B4B),
    ),
  ];

  static const double confidenceThreshold = 0.65;

  /// Lookup by class index (model output)
  static TrashCategory? byIndex(int index) {
    if (index < 0 || index >= categories.length) return null;
    return categories[index];
  }

  /// Lookup by model key string
  static TrashCategory? byKey(String key) {
    try {
      return categories.firstWhere((c) => c.modelKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Compute bonus multiplier for streaks / daily first claim
  static double bonusMultiplier({
    required bool isFirstClaimToday,
    required int currentStreak,
  }) {
    double mult = 1.0;
    if (isFirstClaimToday) mult += 0.5;          // +50% first claim
    if (currentStreak >= 3) mult += 0.25;        // +25% streak ≥ 3 days
    if (currentStreak >= 7) mult += 0.25;        // +25% streak ≥ 7 days
    return mult;
  }
}

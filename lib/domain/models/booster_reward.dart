import 'package:flutter/material.dart';

enum BoosterRewardType {
  flowers,
  gems,
  trayRefresh,
  bloomBomb,
  scoreMultiplier,
  bloomHammer,
  spinToken,
}

class BoosterReward {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String labelShort;
  final String rewardTag;
  final int amount;
  final BoosterRewardType type;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isJackpot;
  final String iconEmoji;
  final String? assetPath;

  const BoosterReward({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.labelShort,
    required this.rewardTag,
    required this.amount,
    required this.type,
    required this.gradientColors,
    required this.accentColor,
    this.isJackpot = false,
    required this.iconEmoji,
    this.assetPath,
  });

  Color get baseColor => gradientColors.first;
}

/// The 8 wedges of the Daily Booster Wheel designed with Block Bloom's signature gem & botanical palette
const List<BoosterReward> kDailyBoosterRewards = [
  // Slice 0 (Top / 12 o'clock) - GRAND JACKPOT!
  BoosterReward(
    id: 'jackpot_500_flowers',
    title: '500 FLOWERS',
    subtitle: 'GRAND JACKPOT!',
    labelShort: '500 🌸',
    rewardTag: 'JACKPOT',
    description: 'Bountiful harvest of 500 flowers to unlock premium garden upgrades!',
    amount: 500,
    type: BoosterRewardType.flowers,
    gradientColors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
    accentColor: Color(0xFFFFD54F),
    isJackpot: true,
    iconEmoji: '👑',
    assetPath: 'assets/flower.png',
  ),

  // Slice 1 (1:30 position) - 2X Sunflower Score Multiplier
  BoosterReward(
    id: 'score_boost_2x',
    title: '2X BOOST',
    subtitle: 'Sunflower Power',
    labelShort: '2X BOOST',
    rewardTag: 'DOUBLE',
    description: 'Doubles all score points gained from line clears in your next game!',
    amount: 1,
    type: BoosterRewardType.scoreMultiplier,
    gradientColors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFBBF24)],
    accentColor: Color(0xFFFEF08A),
    iconEmoji: '🌻',
  ),

  // Slice 2 (3:00 position) - Hydrangea Tray Refreshes
  BoosterReward(
    id: 'tray_refresh_2',
    title: 'TRAY REFRESH',
    subtitle: 'x2 Reshuffles',
    labelShort: 'REFRESH x2',
    rewardTag: 'SWAP',
    description: 'Instantly reshuffles all 3 pieces in your tray when you get stuck!',
    amount: 2,
    type: BoosterRewardType.trayRefresh,
    gradientColors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
    accentColor: Color(0xFFBAE6FD),
    iconEmoji: '🔄',
  ),

  // Slice 3 (4:30 position) - Bloom Bomb
  BoosterReward(
    id: 'bloom_bomb_1',
    title: 'BLOOM BOMB',
    subtitle: 'Petal Blast',
    labelShort: 'BLOOM BOMB',
    rewardTag: 'BLAST',
    description: 'Spawns a powerful 1x1 Bomb block that detonates a 3x3 flower blast!',
    amount: 1,
    type: BoosterRewardType.bloomBomb,
    gradientColors: [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFF87171)],
    accentColor: Color(0xFFFECACA),
    iconEmoji: '💣',
  ),

  // Slice 4 (6:00 position) - Bloom Hammer
  BoosterReward(
    id: 'bloom_hammer_1',
    title: 'BLOOM HAMMER',
    subtitle: 'Tile Breaker',
    labelShort: 'HAMMER',
    rewardTag: 'SMASH',
    description: 'Smashes away any single obstructing block to preserve your combo!',
    amount: 1,
    type: BoosterRewardType.bloomHammer,
    gradientColors: [Color(0xFF6B21A8), Color(0xFF9333EA), Color(0xFFC084FC)],
    accentColor: Color(0xFFF3E8FF),
    iconEmoji: '🔨',
  ),

  // Slice 5 (7:30 position) - 100 Flowers
  BoosterReward(
    id: 'flowers_100',
    title: '100 FLOWERS',
    subtitle: 'Garden Blossom',
    labelShort: '100 🌸',
    rewardTag: 'BLOOM',
    description: 'A cheerful bunch of 100 flowers to decorate your botanical garden.',
    amount: 100,
    type: BoosterRewardType.flowers,
    gradientColors: [Color(0xFF065F46), Color(0xFF10B981), Color(0xFF34D399)],
    accentColor: Color(0xFFA7F3D0),
    iconEmoji: '🌸',
    assetPath: 'assets/small_flower.png',
  ),

  // Slice 6 (9:00 position) - 25 Sparkling Gems
  BoosterReward(
    id: 'gems_25',
    title: '25 GEMS',
    subtitle: 'Sparkling Gems',
    labelShort: '25 💎',
    rewardTag: 'GEMS',
    description: 'Sparkling gems to purchase continues, extra spins & exclusive themes!',
    amount: 25,
    type: BoosterRewardType.gems,
    gradientColors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
    accentColor: Color(0xFFBFDBFE),
    iconEmoji: '💎',
  ),

  // Slice 7 (10:30 position) - 250 Super Bloom Flowers
  BoosterReward(
    id: 'flowers_250',
    title: '250 FLOWERS',
    subtitle: 'Super Bloom',
    labelShort: '250 🌸',
    rewardTag: 'SUPER',
    description: 'Generous 250 flowers reward to level up your garden attractions!',
    amount: 250,
    type: BoosterRewardType.flowers,
    gradientColors: [Color(0xFF9D174D), Color(0xFFDB2777), Color(0xFFF472B6)],
    accentColor: Color(0xFFFBCFE8),
    iconEmoji: '🌺',
    assetPath: 'assets/flower.png',
  ),
];

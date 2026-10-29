/// Represents a daily quest objective
class DailyQuest {
  final String id;
  final String title;
  final String description;
  final int currentProgress;
  final int maxGoal;
  final int rewardAmount;
  final String rewardType; // 'flowers', 'gems', 'token', 'bomb', 'hammer'
  final String rewardEmoji;
  final bool isClaimed;

  const DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.maxGoal,
    required this.rewardAmount,
    required this.rewardType,
    required this.rewardEmoji,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= maxGoal;
  bool get canClaim => isCompleted && !isClaimed;
  double get progressRatio => (currentProgress / maxGoal).clamp(0.0, 1.0);

  DailyQuest copyWith({
    String? id,
    String? title,
    String? description,
    int? currentProgress,
    int? maxGoal,
    int? rewardAmount,
    String? rewardType,
    String? rewardEmoji,
    bool? isClaimed,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      currentProgress: currentProgress ?? this.currentProgress,
      maxGoal: maxGoal ?? this.maxGoal,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardType: rewardType ?? this.rewardType,
      rewardEmoji: rewardEmoji ?? this.rewardEmoji,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

/// Represents a tier in the Garden Season Pass
class GardenPassTier {
  final int tierNumber;
  final int requiredXp;
  final String freeRewardTitle;
  final String freeRewardEmoji;
  final int freeRewardAmount;
  final String vipRewardTitle;
  final String vipRewardEmoji;
  final int vipRewardAmount;
  final bool isFreeClaimed;
  final bool isVipClaimed;

  const GardenPassTier({
    required this.tierNumber,
    required this.requiredXp,
    required this.freeRewardTitle,
    required this.freeRewardEmoji,
    required this.freeRewardAmount,
    required this.vipRewardTitle,
    required this.vipRewardEmoji,
    required this.vipRewardAmount,
    this.isFreeClaimed = false,
    this.isVipClaimed = false,
  });
}

/// Represents an opponent or player in the Episode Race
class RaceParticipant {
  final String name;
  final String avatarPath;
  final int currentLevel;
  final int rank;
  final bool isPlayer;

  const RaceParticipant({
    required this.name,
    required this.avatarPath,
    required this.currentLevel,
    required this.rank,
    this.isPlayer = false,
  });
}

/// Pre-configured initial daily quests for Block Bloom
final List<DailyQuest> kDefaultDailyQuests = [
  const DailyQuest(
    id: 'quest_lines',
    title: 'Line Striker',
    description: 'Clear 15 horizontal or vertical lines in puzzles',
    currentProgress: 11,
    maxGoal: 15,
    rewardAmount: 60,
    rewardType: 'flowers',
    rewardEmoji: '🌸',
  ),
  const DailyQuest(
    id: 'quest_booster',
    title: 'Master Botanist',
    description: 'Deploy 1 Bloom Bomb or Bloom Hammer',
    currentProgress: 1,
    maxGoal: 1,
    rewardAmount: 15,
    rewardType: 'gems',
    rewardEmoji: '💎',
  ),
  const DailyQuest(
    id: 'quest_combo',
    title: 'Combo King',
    description: 'Score a 3x Combo streak or higher',
    currentProgress: 3,
    maxGoal: 3,
    rewardAmount: 1,
    rewardType: 'token',
    rewardEmoji: '🎟️',
  ),
];

/// Pre-configured season pass tiers
final List<GardenPassTier> kDefaultGardenPassTiers = [
  const GardenPassTier(
    tierNumber: 1,
    requiredXp: 100,
    freeRewardTitle: '50 Flowers',
    freeRewardEmoji: '🌸',
    freeRewardAmount: 50,
    vipRewardTitle: 'Tray Refresh x2',
    vipRewardEmoji: '🔄',
    vipRewardAmount: 2,
    isFreeClaimed: true,
  ),
  const GardenPassTier(
    tierNumber: 2,
    requiredXp: 250,
    freeRewardTitle: '10 Gems',
    freeRewardEmoji: '💎',
    freeRewardAmount: 10,
    vipRewardTitle: 'Bloom Hammer x1',
    vipRewardEmoji: '🔨',
    vipRewardAmount: 1,
    isFreeClaimed: true,
  ),
  const GardenPassTier(
    tierNumber: 3,
    requiredXp: 500,
    freeRewardTitle: '100 Flowers',
    freeRewardEmoji: '🌸',
    freeRewardAmount: 100,
    vipRewardTitle: 'Bloom Bomb x1',
    vipRewardEmoji: '💣',
    vipRewardAmount: 1,
    isFreeClaimed: true,
  ),
  const GardenPassTier(
    tierNumber: 4,
    requiredXp: 850,
    freeRewardTitle: '25 Gems',
    freeRewardEmoji: '💎',
    freeRewardAmount: 25,
    vipRewardTitle: '2X Score Multiplier',
    vipRewardEmoji: '⭐',
    vipRewardAmount: 1,
    isFreeClaimed: false,
  ),
  const GardenPassTier(
    tierNumber: 5,
    requiredXp: 1300,
    freeRewardTitle: '200 Flowers',
    freeRewardEmoji: '🌸',
    freeRewardAmount: 200,
    vipRewardTitle: 'Spin Token x2',
    vipRewardEmoji: '🎟️',
    vipRewardAmount: 2,
    isFreeClaimed: false,
  ),
];

/// Pre-configured participants in Episode Race
final List<RaceParticipant> kDefaultRaceParticipants = [
  const RaceParticipant(
    name: 'You',
    avatarPath: 'assets/avatars/avatar_rose.jpg',
    currentLevel: 4,
    rank: 1,
    isPlayer: true,
  ),
  const RaceParticipant(
    name: 'Emma F.',
    avatarPath: 'assets/avatars/avatar_sunflower.jpg',
    currentLevel: 3,
    rank: 2,
  ),
  const RaceParticipant(
    name: 'Leo King',
    avatarPath: 'assets/avatars/avatar_lotus.jpg',
    currentLevel: 2,
    rank: 3,
  ),
  const RaceParticipant(
    name: 'Chloe B.',
    avatarPath: 'assets/avatars/avatar_sunflower.jpg',
    currentLevel: 2,
    rank: 4,
  ),
  const RaceParticipant(
    name: 'Noah W.',
    avatarPath: 'assets/avatars/avatar_rose.jpg',
    currentLevel: 1,
    rank: 5,
  ),
];

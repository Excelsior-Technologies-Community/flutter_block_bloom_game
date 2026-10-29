enum BloomQuestType {
  linesCleared,
  comboStreak,
  flowersEarned,
  dailyGardenPlayed,
  boosterUsed,
  levelsWon,
  highScore,
}

enum BloomQuestCategory {
  daily,
  weekly,
}

/// Represents an authentic Block Bloom puzzle quest
class BloomQuest {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final BloomQuestType type;
  final BloomQuestCategory category;
  final int currentProgress;
  final int targetGoal;
  final int rewardAmount;
  final String rewardType; // 'flowers', 'gems', 'token', 'bomb', 'hammer', 'refresh', 'double_score'
  final String rewardEmoji;
  final bool isClaimed;

  const BloomQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.type,
    required this.category,
    required this.currentProgress,
    required this.targetGoal,
    required this.rewardAmount,
    required this.rewardType,
    required this.rewardEmoji,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetGoal;
  bool get canClaim => isCompleted && !isClaimed;
  double get progressRatio => (currentProgress / targetGoal).clamp(0.0, 1.0);

  BloomQuest copyWith({
    String? id,
    String? title,
    String? description,
    String? iconEmoji,
    BloomQuestType? type,
    BloomQuestCategory? category,
    int? currentProgress,
    int? targetGoal,
    int? rewardAmount,
    String? rewardType,
    String? rewardEmoji,
    bool? isClaimed,
  }) {
    return BloomQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      type: type ?? this.type,
      category: category ?? this.category,
      currentProgress: currentProgress ?? this.currentProgress,
      targetGoal: targetGoal ?? this.targetGoal,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardType: rewardType ?? this.rewardType,
      rewardEmoji: rewardEmoji ?? this.rewardEmoji,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

/// Pre-configured Daily Quests tailored 100% to Block Bloom's actual mechanics
final List<BloomQuest> kDefaultBloomDailyQuests = [
  const BloomQuest(
    id: 'daily_lines',
    title: 'Line Sculptor',
    description: 'Clear 15 horizontal or vertical lines in puzzles',
    iconEmoji: '🌿',
    type: BloomQuestType.linesCleared,
    category: BloomQuestCategory.daily,
    currentProgress: 0,
    targetGoal: 15,
    rewardAmount: 60,
    rewardType: 'flowers',
    rewardEmoji: '🌸',
  ),
  const BloomQuest(
    id: 'daily_combo',
    title: 'Combo Blooming',
    description: 'Score a 3x Combo streak or higher in a match',
    iconEmoji: '⚡',
    type: BloomQuestType.comboStreak,
    category: BloomQuestCategory.daily,
    currentProgress: 0,
    targetGoal: 3,
    rewardAmount: 15,
    rewardType: 'gems',
    rewardEmoji: '💎',
  ),
  const BloomQuest(
    id: 'daily_flowers',
    title: 'Petal Harvester',
    description: 'Collect 100 Flowers across any gameplay modes',
    iconEmoji: '🌸',
    type: BloomQuestType.flowersEarned,
    category: BloomQuestCategory.daily,
    currentProgress: 0,
    targetGoal: 100,
    rewardAmount: 80,
    rewardType: 'flowers',
    rewardEmoji: '🌸',
  ),
  const BloomQuest(
    id: 'daily_garden',
    title: 'Daily Greenery',
    description: 'Complete today\'s Daily Garden Board',
    iconEmoji: '🧩',
    type: BloomQuestType.dailyGardenPlayed,
    category: BloomQuestCategory.daily,
    currentProgress: 0,
    targetGoal: 1,
    rewardAmount: 1,
    rewardType: 'token',
    rewardEmoji: '🎟️',
  ),
  const BloomQuest(
    id: 'daily_booster',
    title: 'Floral Blast',
    description: 'Deploy 1 Bloom Bomb or Bloom Hammer in-game',
    iconEmoji: '💣',
    type: BloomQuestType.boosterUsed,
    category: BloomQuestCategory.daily,
    currentProgress: 0,
    targetGoal: 1,
    rewardAmount: 20,
    rewardType: 'gems',
    rewardEmoji: '💎',
  ),
];

/// Pre-configured Weekly Milestones
final List<BloomQuest> kDefaultBloomWeeklyQuests = [
  const BloomQuest(
    id: 'weekly_levels',
    title: 'Garden Trailblazer',
    description: 'Win 5 Campaign Levels with 2+ stars',
    iconEmoji: '🏆',
    type: BloomQuestType.levelsWon,
    category: BloomQuestCategory.weekly,
    currentProgress: 0,
    targetGoal: 5,
    rewardAmount: 250,
    rewardType: 'flowers',
    rewardEmoji: '🌸',
  ),
  const BloomQuest(
    id: 'weekly_lines',
    title: 'Grand Clearer',
    description: 'Clear 60 total lines across all game modes',
    iconEmoji: '🌟',
    type: BloomQuestType.linesCleared,
    category: BloomQuestCategory.weekly,
    currentProgress: 0,
    targetGoal: 60,
    rewardAmount: 1,
    rewardType: 'bomb',
    rewardEmoji: '💣',
  ),
  const BloomQuest(
    id: 'weekly_score',
    title: 'High Bloomer',
    description: 'Score 5,000+ points in a single puzzle match',
    iconEmoji: '👑',
    type: BloomQuestType.highScore,
    category: BloomQuestCategory.weekly,
    currentProgress: 0,
    targetGoal: 5000,
    rewardAmount: 1,
    rewardType: 'double_score',
    rewardEmoji: '⭐',
  ),
];


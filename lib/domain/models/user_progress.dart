class UserProgress {
  const UserProgress({
    required this.currentLevel,
    required this.highestScore,
    required this.unlockedLevels,
    required this.bestScore,
    required this.bestTimeSeconds,
    this.flowers = 0,
    this.gems = 0,
    this.gardenLevel = 1,
    this.lastDailyPlayedDate = '',
    this.dailyBestScore = 0,
  });

  final int currentLevel;
  final int highestScore;
  final int unlockedLevels;
  final Map<int, int> bestScore;
  final Map<int, int> bestTimeSeconds;
  final int flowers;
  final int gems;
  final int gardenLevel;
  final String lastDailyPlayedDate;
  final int dailyBestScore;

  UserProgress copyWith({
    int? currentLevel,
    int? highestScore,
    int? unlockedLevels,
    Map<int, int>? bestScore,
    Map<int, int>? bestTimeSeconds,
    int? flowers,
    int? gems,
    int? gardenLevel,
    String? lastDailyPlayedDate,
    int? dailyBestScore,
  }) {
    return UserProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      highestScore: highestScore ?? this.highestScore,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      bestScore: bestScore ?? this.bestScore,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      flowers: flowers ?? this.flowers,
      gems: gems ?? this.gems,
      gardenLevel: gardenLevel ?? this.gardenLevel,
      lastDailyPlayedDate: lastDailyPlayedDate ?? this.lastDailyPlayedDate,
      dailyBestScore: dailyBestScore ?? this.dailyBestScore,
    );
  }
}

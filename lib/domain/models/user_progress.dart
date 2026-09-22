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
    this.dailyFlowers = 0,
    this.dailyBlooms = 0,
    this.dailyMaxCombo = 0,
    this.activeTheme = 'assets/decorate/6.png',
    this.unlockedThemes = const ['classic'],
    this.gamesPlayed = 0,
    this.bestCombo = 0,
    this.linesCleared = 0,
    this.totalScore = 0,
    int? totalFlowersCollected,
  }) : totalFlowersCollected = totalFlowersCollected ?? flowers;

  final int currentLevel;
  final int highestScore;
  final int unlockedLevels;
  final Map<int, int> bestScore;
  final Map<int, int> bestTimeSeconds;
  final int flowers;
  final int totalFlowersCollected;
  final int gems;
  final int gardenLevel;
  final String lastDailyPlayedDate;
  final int dailyBestScore;
  final int dailyFlowers;
  final int dailyBlooms;
  final int dailyMaxCombo;
  final String activeTheme;
  final List<String> unlockedThemes;
  final int gamesPlayed;
  final int bestCombo;
  final int linesCleared;
  final int totalScore;

  int get avgScore => gamesPlayed > 0 ? (totalScore / gamesPlayed).round() : 0;

  bool isDailyAttemptCompletedToday(String todayStr) {
    return lastDailyPlayedDate == todayStr && lastDailyPlayedDate.isNotEmpty;
  }

  UserProgress copyWith({
    int? currentLevel,
    int? highestScore,
    int? unlockedLevels,
    Map<int, int>? bestScore,
    Map<int, int>? bestTimeSeconds,
    int? flowers,
    int? totalFlowersCollected,
    int? gems,
    int? gardenLevel,
    String? lastDailyPlayedDate,
    int? dailyBestScore,
    int? dailyFlowers,
    int? dailyBlooms,
    int? dailyMaxCombo,
    String? activeTheme,
    List<String>? unlockedThemes,
    int? gamesPlayed,
    int? bestCombo,
    int? linesCleared,
    int? totalScore,
  }) {
    return UserProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      highestScore: highestScore ?? this.highestScore,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      bestScore: bestScore ?? this.bestScore,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      flowers: flowers ?? this.flowers,
      totalFlowersCollected: totalFlowersCollected ?? this.totalFlowersCollected,
      gems: gems ?? this.gems,
      gardenLevel: gardenLevel ?? this.gardenLevel,
      lastDailyPlayedDate: lastDailyPlayedDate ?? this.lastDailyPlayedDate,
      dailyBestScore: dailyBestScore ?? this.dailyBestScore,
      dailyFlowers: dailyFlowers ?? this.dailyFlowers,
      dailyBlooms: dailyBlooms ?? this.dailyBlooms,
      dailyMaxCombo: dailyMaxCombo ?? this.dailyMaxCombo,
      activeTheme: activeTheme ?? this.activeTheme,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      bestCombo: bestCombo ?? this.bestCombo,
      linesCleared: linesCleared ?? this.linesCleared,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'highestScore': highestScore,
      'unlockedLevels': unlockedLevels,
      'bestScore': bestScore.map((k, v) => MapEntry(k.toString(), v)),
      'bestTimeSeconds': bestTimeSeconds.map((k, v) => MapEntry(k.toString(), v)),
      'flowers': flowers,
      'totalFlowersCollected': totalFlowersCollected,
      'gems': gems,
      'gardenLevel': gardenLevel,
      'lastDailyPlayedDate': lastDailyPlayedDate,
      'dailyBestScore': dailyBestScore,
      'dailyFlowers': dailyFlowers,
      'dailyBlooms': dailyBlooms,
      'dailyMaxCombo': dailyMaxCombo,
      'activeTheme': activeTheme,
      'unlockedThemes': unlockedThemes,
      'gamesPlayed': gamesPlayed,
      'bestCombo': bestCombo,
      'linesCleared': linesCleared,
      'totalScore': totalScore,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final rawBestScore = json['bestScore'];
    final Map<int, int> bestScore = (rawBestScore is Map)
        ? rawBestScore.map((k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ))
        : {};

    final rawBestTime = json['bestTimeSeconds'];
    final Map<int, int> bestTimeSeconds = (rawBestTime is Map)
        ? rawBestTime.map((k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ))
        : {};

    final rawUnlockedThemes = json['unlockedThemes'];
    final unlockedThemes = (rawUnlockedThemes is List)
        ? rawUnlockedThemes.map((e) => e.toString()).toList()
        : <String>['classic'];

    final flowersVal = (json['flowers'] as num?)?.toInt() ?? 0;
    final totalFlowersVal = (json['totalFlowersCollected'] as num?)?.toInt() ?? flowersVal;

    return UserProgress(
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
      highestScore: (json['highestScore'] as num?)?.toInt() ?? 0,
      unlockedLevels: (json['unlockedLevels'] as num?)?.toInt() ?? 1,
      bestScore: bestScore,
      bestTimeSeconds: bestTimeSeconds,
      flowers: flowersVal,
      totalFlowersCollected: totalFlowersVal > flowersVal ? totalFlowersVal : flowersVal,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      gardenLevel: (json['gardenLevel'] as num?)?.toInt() ?? 1,
      lastDailyPlayedDate: (json['lastDailyPlayedDate'] as String?) ?? '',
      dailyBestScore: (json['dailyBestScore'] as num?)?.toInt() ?? 0,
      dailyFlowers: (json['dailyFlowers'] as num?)?.toInt() ?? 0,
      dailyBlooms: (json['dailyBlooms'] as num?)?.toInt() ?? 0,
      dailyMaxCombo: (json['dailyMaxCombo'] as num?)?.toInt() ?? 0,
      activeTheme: (json['activeTheme'] as String?) ?? 'assets/decorate/6.png',
      unlockedThemes: unlockedThemes,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      bestCombo: (json['bestCombo'] as num?)?.toInt() ?? 0,
      linesCleared: (json['linesCleared'] as num?)?.toInt() ?? 0,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
    );
  }
}


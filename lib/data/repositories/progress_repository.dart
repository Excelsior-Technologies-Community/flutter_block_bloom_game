import 'package:flutter/foundation.dart';
import 'package:block_bloom/data/services/hive_service.dart';
import 'package:block_bloom/domain/models/user_progress.dart';

class ProgressRepository extends ChangeNotifier {
  ProgressRepository({required this.hiveService});

  final HiveService hiveService;

  Future<UserProgress> getProgress() async {
    final box = hiveService.progressBox;
    final currentLevel = box.get('currentLevel', defaultValue: 1) as int;
    final highestScore = box.get('highestScore', defaultValue: 0) as int;
    final unlockedLevels = box.get('unlockedLevels', defaultValue: 1) as int;
    
    final rawBestScore = box.get('bestScore', defaultValue: <dynamic, dynamic>{});
    final Map<int, int> bestScore = rawBestScore is Map
        ? rawBestScore.map(
            (k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ),
          )
        : {};

    final rawBestTime = box.get('bestTimeSeconds', defaultValue: <dynamic, dynamic>{});
    final Map<int, int> bestTimeSeconds = rawBestTime is Map
        ? rawBestTime.map(
            (k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ),
          )
        : {};

    final flowers = box.get('flowers', defaultValue: 0) as int;
    final gems = box.get('gems', defaultValue: 0) as int;
    final gardenLevel = box.get('gardenLevel', defaultValue: 1) as int;
    final lastDailyPlayedDate = box.get('lastDailyPlayedDate', defaultValue: '') as String;
    final dailyBestScore = box.get('dailyBestScore', defaultValue: 0) as int;

    final activeTheme = box.get('activeTheme', defaultValue: 'assets/decorate/6.png') as String;
    final rawUnlockedThemes = box.get('unlockedThemes', defaultValue: <dynamic>['classic']);
    final unlockedThemes = (rawUnlockedThemes is List)
        ? rawUnlockedThemes.map((e) => e.toString()).toList()
        : <String>['classic'];

    return UserProgress(
      currentLevel: currentLevel,
      highestScore: highestScore,
      unlockedLevels: unlockedLevels,
      bestScore: bestScore,
      bestTimeSeconds: bestTimeSeconds,
      flowers: flowers,
      gems: gems,
      gardenLevel: gardenLevel,
      lastDailyPlayedDate: lastDailyPlayedDate,
      dailyBestScore: dailyBestScore,
      activeTheme: activeTheme,
      unlockedThemes: unlockedThemes,
    );
  }

  Future<void> saveProgress(UserProgress progress) async {
    final box = hiveService.progressBox;
    await box.put('currentLevel', progress.currentLevel);
    await box.put('highestScore', progress.highestScore);
    await box.put('unlockedLevels', progress.unlockedLevels);
    await box.put('bestScore', progress.bestScore);
    await box.put('bestTimeSeconds', progress.bestTimeSeconds);
    await box.put('flowers', progress.flowers);
    await box.put('gems', progress.gems);
    await box.put('gardenLevel', progress.gardenLevel);
    await box.put('lastDailyPlayedDate', progress.lastDailyPlayedDate);
    await box.put('dailyBestScore', progress.dailyBestScore);
    await box.put('activeTheme', progress.activeTheme);
    await box.put('unlockedThemes', progress.unlockedThemes);
    notifyListeners();
  }

  Future<void> setActiveTheme(String themeAsset) async {
    final current = await getProgress();
    final updated = current.copyWith(activeTheme: themeAsset);
    await saveProgress(updated);
  }

  Future<bool> unlockTheme(String themeId, int flowerCost, String themeAsset) async {
    final current = await getProgress();
    if (current.flowers >= flowerCost && !current.unlockedThemes.contains(themeId)) {
      final updatedUnlocked = [...current.unlockedThemes, themeId];
      final updated = current.copyWith(
        flowers: current.flowers - flowerCost,
        unlockedThemes: updatedUnlocked,
        activeTheme: themeAsset,
      );
      await saveProgress(updated);
      return true;
    }
    return false;
  }

  Future<void> addFlowers(int amount) async {
    final current = await getProgress();
    final updated = current.copyWith(flowers: current.flowers + amount);
    await saveProgress(updated);
  }

  Future<bool> upgradeGarden(int flowerCost) async {
    final current = await getProgress();
    if (current.flowers >= flowerCost && current.gardenLevel < 6) {
      final updated = current.copyWith(
        flowers: current.flowers - flowerCost,
        gardenLevel: current.gardenLevel + 1,
      );
      await saveProgress(updated);
      return true;
    }
    return false;
  }

  Future<void> saveDailyScore(int score, String dateStr) async {
    final current = await getProgress();
    final newDailyBest = score > current.dailyBestScore ? score : current.dailyBestScore;
    final updated = current.copyWith(
      lastDailyPlayedDate: dateStr,
      dailyBestScore: newDailyBest,
      highestScore: score > current.highestScore ? score : current.highestScore,
    );
    await saveProgress(updated);
  }

  Future<void> saveLevelCompletion({
    required int levelNumber,
    required int score,
    required int elapsedSeconds,
  }) async {
    final current = await getProgress();
    final newUnlocked = levelNumber >= current.unlockedLevels 
        ? levelNumber + 1 
        : current.unlockedLevels;

    final newCurrentLevel = levelNumber >= current.currentLevel 
        ? levelNumber + 1 
        : current.currentLevel;

    final newHighestScore = score > current.highestScore ? score : current.highestScore;

    final newBestScore = Map<int, int>.from(current.bestScore);
    if (!newBestScore.containsKey(levelNumber) || score > newBestScore[levelNumber]!) {
      newBestScore[levelNumber] = score;
    }

    final newBestTime = Map<int, int>.from(current.bestTimeSeconds);
    if (!newBestTime.containsKey(levelNumber) || elapsedSeconds < newBestTime[levelNumber]!) {
      newBestTime[levelNumber] = elapsedSeconds;
    }

    final updated = current.copyWith(
      currentLevel: newCurrentLevel,
      highestScore: newHighestScore,
      unlockedLevels: newUnlocked,
      bestScore: newBestScore,
      bestTimeSeconds: newBestTime,
    );

    await saveProgress(updated);
  }
}

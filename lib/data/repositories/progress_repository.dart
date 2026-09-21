import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:block_bloom/data/services/hive_service.dart';
import 'package:block_bloom/domain/models/user_progress.dart';

class ProgressRepository extends ChangeNotifier {
  ProgressRepository({required this.hiveService});

  final HiveService hiveService;
  String? _currentUserId;

  String get currentUserId => _currentUserId ?? '';

  void setCurrentUser(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null && userId.isNotEmpty) {
        _ensureUserInitialized(userId).then((_) {
          syncWithFirebase(userId);
        });
      }
      notifyListeners();
    }
  }

  Future<void> _ensureUserInitialized(String userId) async {
    final box = hiveService.progressBox;

    // Remove legacy unprefixed keys from early testing if present
    final legacyKeys = [
      'highestScore',
      'flowers',
      'gems',
      'gamesPlayed',
      'bestCombo',
      'linesCleared',
      'totalScore',
      'dailyBestScore',
    ];
    for (final k in legacyKeys) {
      if (box.containsKey(k)) {
        await box.delete(k);
      }
    }

    final userKey = 'highestScore_$userId';
    if (!box.containsKey(userKey)) {
      const cleanProgress = UserProgress(
        currentLevel: 1,
        highestScore: 0,
        unlockedLevels: 1,
        bestScore: {},
        bestTimeSeconds: {},
        flowers: 0,
        gems: 0,
        gardenLevel: 1,
        gamesPlayed: 0,
        bestCombo: 0,
        linesCleared: 0,
        totalScore: 0,
      );
      await _saveToLocal(cleanProgress);
    }
  }

  String _getKey(String field) {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return '${field}_$_currentUserId';
    }
    return field;
  }

  Future<void> syncWithFirebase(String userId) async {
    if (userId.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null && docSnap.data()!['stats'] != null) {
        final rawStats = docSnap.data()!['stats'];
        if (rawStats is Map) {
          final cloudProgress = UserProgress.fromJson(Map<String, dynamic>.from(rawStats));
          await _saveToLocal(cloudProgress);
          notifyListeners();
          return;
        }
      }

      // If no stats document exists in Firestore, push local stats to Firestore
      final localProgress = await getProgress();
      await docRef.set({
        'stats': localProgress.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync note: $e');
    }
  }

  Future<UserProgress> getProgress() async {
    final box = hiveService.progressBox;

    int getInt(String field, int defaultValue) {
      final userKey = _getKey(field);
      dynamic raw;
      if (box.containsKey(userKey)) {
        raw = box.get(userKey);
      } else if (_currentUserId == null || _currentUserId!.isEmpty) {
        if (box.containsKey(field)) {
          raw = box.get(field);
        }
      }
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? defaultValue;
      return defaultValue;
    }

    final currentLevel = getInt('currentLevel', 1);
    final highestScore = getInt('highestScore', 0);
    final unlockedLevels = getInt('unlockedLevels', 1);

    final dynamic rawBestScore = box.containsKey(_getKey('bestScore'))
        ? box.get(_getKey('bestScore'))
        : ((_currentUserId == null || _currentUserId!.isEmpty) ? box.get('bestScore') : null);
    final Map<int, int> bestScore = (rawBestScore is Map)
        ? rawBestScore.map(
            (k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ),
          )
        : {};

    final dynamic rawBestTime = box.containsKey(_getKey('bestTimeSeconds'))
        ? box.get(_getKey('bestTimeSeconds'))
        : ((_currentUserId == null || _currentUserId!.isEmpty) ? box.get('bestTimeSeconds') : null);
    final Map<int, int> bestTimeSeconds = (rawBestTime is Map)
        ? rawBestTime.map(
            (k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ),
          )
        : {};

    final flowers = getInt('flowers', 0);
    final gems = getInt('gems', 0);
    final gardenLevel = getInt('gardenLevel', 1);
    final lastDailyPlayedDate = box.containsKey(_getKey('lastDailyPlayedDate'))
        ? (box.get(_getKey('lastDailyPlayedDate'), defaultValue: '') as String)
        : ((_currentUserId == null || _currentUserId!.isEmpty)
            ? (box.get('lastDailyPlayedDate', defaultValue: '') as String)
            : '');
    final dailyBestScore = getInt('dailyBestScore', 0);

    final activeTheme = box.containsKey(_getKey('activeTheme'))
        ? (box.get(_getKey('activeTheme'), defaultValue: 'assets/decorate/6.png') as String)
        : ((_currentUserId == null || _currentUserId!.isEmpty)
            ? (box.get('activeTheme', defaultValue: 'assets/decorate/6.png') as String)
            : 'assets/decorate/6.png');

    final dynamic rawUnlockedThemes = box.containsKey(_getKey('unlockedThemes'))
        ? box.get(_getKey('unlockedThemes'))
        : ((_currentUserId == null || _currentUserId!.isEmpty) ? box.get('unlockedThemes') : null);
    final unlockedThemes = (rawUnlockedThemes is List)
        ? rawUnlockedThemes.map((e) => e.toString()).toList()
        : <String>['classic'];

    final gamesPlayed = getInt('gamesPlayed', 0);
    final bestCombo = getInt('bestCombo', 0);
    final linesCleared = getInt('linesCleared', 0);
    final totalScore = getInt('totalScore', 0);

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
      gamesPlayed: gamesPlayed,
      bestCombo: bestCombo,
      linesCleared: linesCleared,
      totalScore: totalScore,
    );
  }

  Future<void> _saveToLocal(UserProgress progress) async {
    final box = hiveService.progressBox;
    await box.put(_getKey('currentLevel'), progress.currentLevel);
    await box.put(_getKey('highestScore'), progress.highestScore);
    await box.put(_getKey('unlockedLevels'), progress.unlockedLevels);
    await box.put(_getKey('bestScore'), progress.bestScore);
    await box.put(_getKey('bestTimeSeconds'), progress.bestTimeSeconds);
    await box.put(_getKey('flowers'), progress.flowers);
    await box.put(_getKey('gems'), progress.gems);
    await box.put(_getKey('gardenLevel'), progress.gardenLevel);
    await box.put(_getKey('lastDailyPlayedDate'), progress.lastDailyPlayedDate);
    await box.put(_getKey('dailyBestScore'), progress.dailyBestScore);
    await box.put(_getKey('activeTheme'), progress.activeTheme);
    await box.put(_getKey('unlockedThemes'), progress.unlockedThemes);
    await box.put(_getKey('gamesPlayed'), progress.gamesPlayed);
    await box.put(_getKey('bestCombo'), progress.bestCombo);
    await box.put(_getKey('linesCleared'), progress.linesCleared);
    await box.put(_getKey('totalScore'), progress.totalScore);
  }

  Future<void> saveProgress(UserProgress progress) async {
    await _saveToLocal(progress);

    // Sync with Firebase Firestore if a user is logged in
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      try {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .set({
          'stats': progress.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore save error: $e');
      }
    }

    notifyListeners();
  }

  Future<void> recordGameStarted() async {
    final current = await getProgress();
    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
    );
    await saveProgress(updated);
  }

  Future<void> recordGameProgress({
    required int score,
    required int linesClearedInGame,
    required int maxCombo,
  }) async {
    final current = await getProgress();
    final updated = current.copyWith(
      highestScore: max(current.highestScore, score),
      bestCombo: max(current.bestCombo, maxCombo),
    );
    await saveProgress(updated);
  }

  Future<void> recordGameFinished({
    required int score,
    required int linesClearedInGame,
    required int maxCombo,
    required int flowersEarned,
  }) async {
    final current = await getProgress();
    final updated = current.copyWith(
      highestScore: max(current.highestScore, score),
      bestCombo: max(current.bestCombo, maxCombo),
      linesCleared: current.linesCleared + linesClearedInGame,
      totalScore: current.totalScore + score,
    );
    await saveProgress(updated);
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

  String getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> isDailyCompletedToday() async {
    final progress = await getProgress();
    final today = getTodayDateString();
    return progress.isDailyAttemptCompletedToday(today);
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


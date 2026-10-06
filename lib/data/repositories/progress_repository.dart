import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:block_bloom/data/services/hive_service.dart';
import 'package:block_bloom/domain/models/user_progress.dart';

class ProgressRepository extends ChangeNotifier {
  ProgressRepository({required this.hiveService});

  final HiveService hiveService;
  String? _currentUserId;

  String get currentUserId => _currentUserId ?? '';

  Future<void> setCurrentUser(String? userId, {String? displayName}) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
    }
    if (userId != null && userId.isNotEmpty) {
      await syncAndMergeProgress(userId, displayName: displayName);
    } else {
      notifyListeners();
    }
  }

  String _getKey(String field, {String? targetUserId}) {
    final uid = targetUserId ?? _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      return '${field}_$uid';
    }
    return field;
  }

  UserProgress mergeUserProgress(UserProgress a, UserProgress b) {
    final flowersMerged = max(a.flowers, b.flowers);
    final totalFlowersMerged = max(max(a.totalFlowers, b.totalFlowers), flowersMerged);

    return UserProgress(
      currentLevel: max(a.currentLevel, b.currentLevel),
      highestScore: max(a.highestScore, b.highestScore),
      unlockedLevels: max(a.unlockedLevels, b.unlockedLevels),
      bestScore: _mergeIntMaps(a.bestScore, b.bestScore),
      bestTimeSeconds: _mergeBestTimes(a.bestTimeSeconds, b.bestTimeSeconds),
      flowers: flowersMerged,
      totalFlowers: totalFlowersMerged,
      gems: max(a.gems, b.gems),
      gardenLevel: max(a.gardenLevel, b.gardenLevel),
      lastDailyPlayedDate: a.lastDailyPlayedDate.compareTo(b.lastDailyPlayedDate) >= 0
          ? a.lastDailyPlayedDate
          : b.lastDailyPlayedDate,
      dailyBestScore: max(a.dailyBestScore, b.dailyBestScore),
      dailyFlowers: max(a.dailyFlowers, b.dailyFlowers),
      dailyBlooms: max(a.dailyBlooms, b.dailyBlooms),
      dailyMaxCombo: max(a.dailyMaxCombo, b.dailyMaxCombo),
      activeTheme: a.activeTheme.isNotEmpty ? a.activeTheme : b.activeTheme,
      unlockedThemes: {...a.unlockedThemes, ...b.unlockedThemes}.toList(),
      gamesPlayed: max(a.gamesPlayed, b.gamesPlayed),
      bestCombo: max(a.bestCombo, b.bestCombo),
      linesCleared: max(a.linesCleared, b.linesCleared),
      totalScore: max(a.totalScore, b.totalScore),
    );
  }

  Future<void> _clearGuestKeys() async {
    final box = hiveService.progressBox;
    final guestKeys = [
      'currentLevel',
      'highestScore',
      'unlockedLevels',
      'bestScore',
      'bestTimeSeconds',
      'flowers',
      'totalFlowers',
      'gems',
      'gardenLevel',
      'lastDailyPlayedDate',
      'dailyBestScore',
      'dailyFlowers',
      'dailyBlooms',
      'dailyMaxCombo',
      'activeTheme',
      'unlockedThemes',
      'gamesPlayed',
      'bestCombo',
      'linesCleared',
      'totalScore',
    ];
    for (final k in guestKeys) {
      if (box.containsKey(k)) {
        await box.delete(k);
      }
    }
  }

  Future<void> syncAndMergeProgress(String userId, {String? displayName}) async {
    if (userId.isEmpty) return;

    try {
      // 1. Fetch guest progress (if user played as guest before signin)
      final guestProgress = await _getProgressForId(null);
      final bool hasGuestProgress = guestProgress.highestScore > 0 ||
          guestProgress.flowers > 0 ||
          guestProgress.gamesPlayed > 0 ||
          guestProgress.currentLevel > 1 ||
          guestProgress.linesCleared > 0;

      // 2. Fetch local user progress for this userId
      final localUserProgress = await _getProgressForId(userId);

      // 3. Fetch cloud progress from Firestore
      UserProgress? cloudProgress;
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        Map<String, dynamic> statsMap = {};
        if (data['stats'] is Map) {
          statsMap = Map<String, dynamic>.from(data['stats']);
        }
        for (final entry in data.entries) {
          if (entry.key != 'stats' && entry.key != 'updatedAt') {
            statsMap.putIfAbsent(entry.key, () => entry.value);
          }
        }
        if (statsMap.isNotEmpty) {
          cloudProgress = UserProgress.fromJson(statsMap);
        }
      }

      // 4. Merge all sources safely
      UserProgress merged = localUserProgress;
      if (cloudProgress != null) {
        merged = mergeUserProgress(merged, cloudProgress);
      }
      if (hasGuestProgress) {
        merged = mergeUserProgress(merged, guestProgress);
      }

      // 5. Save merged progress to local Hive for this userId
      await _saveToLocalForId(userId, merged);

      // 6. Clear guest keys after successful migration
      if (hasGuestProgress) {
        await _clearGuestKeys();
      }

      // 7. Push merged progress to Firestore
      String? resolvedName = displayName;
      if (resolvedName == null || resolvedName.trim().isEmpty) {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          resolvedName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
              ? fbUser.displayName!.trim()
              : (fbUser.email != null && fbUser.email!.contains('@')
                  ? fbUser.email!.split('@').first
                  : null);
        }
      }

      final jsonMap = merged.toJson();
      final firestoreData = <String, dynamic>{
        'stats': jsonMap,
        ...jsonMap,
        'uid': userId,
        if (resolvedName != null && resolvedName.trim().isNotEmpty) 'displayName': resolvedName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(firestoreData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ProgressRepository sync error: $e');
    } finally {
      notifyListeners();
    }
  }

  Map<int, int> _mergeIntMaps(Map<int, int> map1, Map<int, int> map2) {
    final result = Map<int, int>.from(map1);
    map2.forEach((key, val) {
      if (!result.containsKey(key) || val > result[key]!) {
        result[key] = val;
      }
    });
    return result;
  }

  Map<int, int> _mergeBestTimes(Map<int, int> map1, Map<int, int> map2) {
    final result = Map<int, int>.from(map1);
    map2.forEach((key, val) {
      if (!result.containsKey(key) || val < result[key]!) {
        result[key] = val;
      }
    });
    return result;
  }

  Future<UserProgress> getProgress() async {
    return _getProgressForId(_currentUserId);
  }

  Future<UserProgress> _getProgressForId(String? targetUserId) async {
    final box = hiveService.progressBox;

    int getInt(String field, int defaultValue) {
      final userKey = _getKey(field, targetUserId: targetUserId);
      dynamic raw;
      if (box.containsKey(userKey)) {
        raw = box.get(userKey);
      } else if (targetUserId == null || targetUserId.isEmpty) {
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

    final bestScoreKey = _getKey('bestScore', targetUserId: targetUserId);
    final dynamic rawBestScore = box.containsKey(bestScoreKey)
        ? box.get(bestScoreKey)
        : ((targetUserId == null || targetUserId.isEmpty) ? box.get('bestScore') : null);
    final Map<int, int> bestScore = (rawBestScore is Map)
        ? rawBestScore.map(
            (k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ),
          )
        : {};

    final bestTimeKey = _getKey('bestTimeSeconds', targetUserId: targetUserId);
    final dynamic rawBestTime = box.containsKey(bestTimeKey)
        ? box.get(bestTimeKey)
        : ((targetUserId == null || targetUserId.isEmpty) ? box.get('bestTimeSeconds') : null);
    final Map<int, int> bestTimeSeconds = (rawBestTime is Map)
        ? rawBestTime.map(
            (k, v) => MapEntry(
              k is int ? k : (int.tryParse(k.toString()) ?? 0),
              v is int ? v : (v is num ? v.toInt() : 0),
            ),
          )
        : {};

    final flowers = getInt('flowers', 0);
    final totalFlowers = max(getInt('totalFlowers', 0), flowers);
    final gems = getInt('gems', 0);
    final gardenLevel = getInt('gardenLevel', 1);

    final dailyDateKey = _getKey('lastDailyPlayedDate', targetUserId: targetUserId);
    final lastDailyPlayedDate = box.containsKey(dailyDateKey)
        ? (box.get(dailyDateKey, defaultValue: '') as String)
        : ((targetUserId == null || targetUserId.isEmpty)
            ? (box.get('lastDailyPlayedDate', defaultValue: '') as String)
            : '');

    final dailyBestScore = getInt('dailyBestScore', 0);
    final dailyFlowers = getInt('dailyFlowers', 0);
    final dailyBlooms = getInt('dailyBlooms', 0);
    final dailyMaxCombo = getInt('dailyMaxCombo', 0);

    final activeThemeKey = _getKey('activeTheme', targetUserId: targetUserId);
    final activeTheme = box.containsKey(activeThemeKey)
        ? (box.get(activeThemeKey, defaultValue: '') as String)
        : ((targetUserId == null || targetUserId.isEmpty)
            ? (box.get('activeTheme', defaultValue: '') as String)
            : '');

    final unlockedThemesKey = _getKey('unlockedThemes', targetUserId: targetUserId);
    final dynamic rawUnlockedThemes = box.containsKey(unlockedThemesKey)
        ? box.get(unlockedThemesKey)
        : ((targetUserId == null || targetUserId.isEmpty) ? box.get('unlockedThemes') : null);
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
      totalFlowers: totalFlowers,
      gems: gems,
      gardenLevel: gardenLevel,
      lastDailyPlayedDate: lastDailyPlayedDate,
      dailyBestScore: dailyBestScore,
      dailyFlowers: dailyFlowers,
      dailyBlooms: dailyBlooms,
      dailyMaxCombo: dailyMaxCombo,
      activeTheme: activeTheme,
      unlockedThemes: unlockedThemes,
      gamesPlayed: gamesPlayed,
      bestCombo: bestCombo,
      linesCleared: linesCleared,
      totalScore: totalScore,
    );
  }

  Future<void> _saveToLocal(UserProgress progress) async {
    await _saveToLocalForId(_currentUserId, progress);
  }

  Future<void> _saveToLocalForId(String? targetUserId, UserProgress progress) async {
    final box = hiveService.progressBox;
    await box.put(_getKey('currentLevel', targetUserId: targetUserId), progress.currentLevel);
    await box.put(_getKey('highestScore', targetUserId: targetUserId), progress.highestScore);
    await box.put(_getKey('unlockedLevels', targetUserId: targetUserId), progress.unlockedLevels);
    await box.put(_getKey('bestScore', targetUserId: targetUserId), progress.bestScore);
    await box.put(_getKey('bestTimeSeconds', targetUserId: targetUserId), progress.bestTimeSeconds);
    await box.put(_getKey('flowers', targetUserId: targetUserId), progress.flowers);
    await box.put(_getKey('totalFlowers', targetUserId: targetUserId), progress.totalFlowers);
    await box.put(_getKey('gems', targetUserId: targetUserId), progress.gems);
    await box.put(_getKey('gardenLevel', targetUserId: targetUserId), progress.gardenLevel);
    await box.put(_getKey('lastDailyPlayedDate', targetUserId: targetUserId), progress.lastDailyPlayedDate);
    await box.put(_getKey('dailyBestScore', targetUserId: targetUserId), progress.dailyBestScore);
    await box.put(_getKey('dailyFlowers', targetUserId: targetUserId), progress.dailyFlowers);
    await box.put(_getKey('dailyBlooms', targetUserId: targetUserId), progress.dailyBlooms);
    await box.put(_getKey('dailyMaxCombo', targetUserId: targetUserId), progress.dailyMaxCombo);
    await box.put(_getKey('activeTheme', targetUserId: targetUserId), progress.activeTheme);
    await box.put(_getKey('unlockedThemes', targetUserId: targetUserId), progress.unlockedThemes);
    await box.put(_getKey('gamesPlayed', targetUserId: targetUserId), progress.gamesPlayed);
    await box.put(_getKey('bestCombo', targetUserId: targetUserId), progress.bestCombo);
    await box.put(_getKey('linesCleared', targetUserId: targetUserId), progress.linesCleared);
    await box.put(_getKey('totalScore', targetUserId: targetUserId), progress.totalScore);
  }

  Future<void> saveProgress(UserProgress progress, {String? displayName}) async {
    final calculatedTotal = max(progress.totalFlowers, progress.flowers);
    final progressToSave = progress.totalFlowers != calculatedTotal
        ? progress.copyWith(totalFlowers: calculatedTotal)
        : progress;

    await _saveToLocal(progressToSave);

    // Sync with Firebase Firestore if a user is logged in
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      try {
        String? resolvedName = displayName;
        if (resolvedName == null || resolvedName.trim().isEmpty) {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null) {
            resolvedName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
                ? fbUser.displayName!.trim()
                : (fbUser.email != null && fbUser.email!.contains('@')
                    ? fbUser.email!.split('@').first
                    : null);
          }
        }

        final jsonMap = progressToSave.toJson();
        final firestoreData = <String, dynamic>{
          'stats': jsonMap,
          ...jsonMap,
          'uid': _currentUserId,
          if (resolvedName != null && resolvedName.trim().isNotEmpty) 'displayName': resolvedName.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .set(firestoreData, SetOptions(merge: true));
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
    final newFlowers = current.flowers + flowersEarned;
    final newTotalFlowers = current.totalFlowers + flowersEarned;

    final updated = current.copyWith(
      highestScore: max(current.highestScore, score),
      bestCombo: max(current.bestCombo, maxCombo),
      linesCleared: current.linesCleared + linesClearedInGame,
      totalScore: current.totalScore + score,
      flowers: newFlowers,
      totalFlowers: newTotalFlowers,
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
    final newFlowers = current.flowers + amount;
    final newTotalFlowers = current.totalFlowers + amount;
    final updated = current.copyWith(
      flowers: newFlowers,
      totalFlowers: newTotalFlowers,
    );
    await saveProgress(updated);
  }

  Future<bool> upgradeGarden(int flowerCost) async {
    final current = await getProgress();
    if (current.flowers >= flowerCost && current.gardenLevel < 6) {
      final nextLvl = current.gardenLevel + 1;
      final updated = current.copyWith(
        flowers: current.flowers - flowerCost,
        gardenLevel: nextLvl,
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

  Future<void> saveDailyScore(
    int score,
    String dateStr, {
    int flowers = 0,
    int blooms = 0,
    int maxCombo = 0,
    bool isFinal = false,
  }) async {
    final current = await getProgress();
    final isSameDay = current.lastDailyPlayedDate == dateStr;

    final newDailyBest = (isSameDay && current.dailyBestScore > score) ? current.dailyBestScore : score;
    final newDailyFlowers = (isSameDay && current.dailyFlowers > flowers) ? current.dailyFlowers : flowers;
    final newDailyBlooms = (isSameDay && current.dailyBlooms > blooms) ? current.dailyBlooms : blooms;
    final newDailyMaxCombo = (isSameDay && current.dailyMaxCombo > maxCombo) ? current.dailyMaxCombo : maxCombo;

    final updated = current.copyWith(
      lastDailyPlayedDate: dateStr,
      dailyBestScore: newDailyBest,
      dailyFlowers: newDailyFlowers,
      dailyBlooms: newDailyBlooms,
      dailyMaxCombo: newDailyMaxCombo,
      highestScore: max(current.highestScore, score),
      bestCombo: max(current.bestCombo, maxCombo),
      linesCleared: isFinal ? (current.linesCleared + blooms) : current.linesCleared,
      totalScore: isFinal ? (current.totalScore + score) : current.totalScore,
    );
    await saveProgress(updated);
  }

  Future<void> saveLevelCompletion({
    required int levelNumber,
    required int score,
    required int elapsedSeconds,
    int flowersEarned = 0,
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
      flowers: current.flowers + flowersEarned,
      totalFlowers: current.totalFlowers + flowersEarned,
    );

    await saveProgress(updated);
  }
}


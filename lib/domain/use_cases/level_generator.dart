import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:block_bloom/domain/models/game_level.dart';

class LevelGenerator {
  final Map<int, GameLevel> _cache = {};
  final Set<int> _generating = {};

  GameLevel generate(int levelNumber) {
    GameLevel level;
    if (_cache.containsKey(levelNumber)) {
      level = _cache.remove(levelNumber)!;
    } else {
      level = _generateInternal(levelNumber);
    }
    _generating.remove(levelNumber);
    
    _pregenerateNext(levelNumber + 1);
    return level;
  }

  /// Calculates matrix grid size based on level progression.
  /// Mentors can easily adjust or revert the level matrix sizing criteria below.
  static int getGridSizeForLevel(int levelNumber) {
    if (levelNumber <= 2) {
      return 5; // Level 1 - 2: 5x5 matrix (small matrix for initial levels)
    } else if (levelNumber <= 5) {
      return 6; // Level 3 - 5: 6x6 matrix (increasing matrix size)
    } else if (levelNumber <= 9) {
      return 7; // Level 6 - 9: 7x7 matrix (medium-large matrix)
    } else {
      return 8; // Level 10+: 8x8 matrix (full standard size)
    }
  }

  GameLevel _generateInternal(int levelNumber) {
    final random = Random(levelNumber * 7919);
    
    // =========================================================================
    // EXISTING CODE (COMMENTED OUT FOR MENTOR REVIEW):
    // final gridSize = 8;
    // =========================================================================

    // NEW CODE: Progressive matrix size increasing level by level
    final gridSize = getGridSizeForLevel(levelNumber);

    return _generateLevelWithSeed(levelNumber, gridSize, random);
  }

  void _pregenerateNext(int startLevel) {
    for (int i = 0; i < 3; i++) {
      final levelNumber = startLevel + i;
      if (!_cache.containsKey(levelNumber) && !_generating.contains(levelNumber)) {
        _generating.add(levelNumber);
        compute(_isolateGenerate, levelNumber).then((level) {
          _cache[levelNumber] = level;
          _generating.remove(levelNumber);
        }).catchError((e) {
          _generating.remove(levelNumber);
        });
      }
    }
  }

  static GameLevel _isolateGenerate(int levelNumber) {
    return LevelGenerator()._generateInternal(levelNumber);
  }

  GameLevel generateRandom({required int gridSize, required int seed}) {
    final random = Random(seed);
    return _generateLevelWithSeed(-1, gridSize, random);
  }

  GameLevel generateDaily(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    return _generateLevelWithSeed(-99, 8, random);
  }

  /// Calculates target completion score based on level progression & matrix size.
  /// Mentors can easily adjust or revert the target score scaling criteria below.
  static int getTargetScoreForLevel(int levelNumber, int gridSize) {
    if (levelNumber <= 0) return 3000; // Default target score for random/daily puzzles

    if (levelNumber == 1) {
      return 1000; // Level 1 (5x5 matrix): Minimal score for easy tutorial
    } else if (levelNumber == 2) {
      return 1500; // Level 2 (5x5 matrix): Low score requirement
    } else if (levelNumber == 3) {
      return 2500; // Level 3 (6x6 matrix): Moderate entry score
    } else if (levelNumber <= 5) {
      return 2500 + ((levelNumber - 3) * 1000); // Level 4-5 (6x6): 3500 - 4500 pts
    } else if (levelNumber <= 9) {
      return 5000 + ((levelNumber - 5) * 1500); // Level 6-9 (7x7): 6500 - 11000 pts
    } else {
      return min(25000, 11000 + ((levelNumber - 9) * 2000)); // Level 10+ (8x8): Scaling up to 25000 max
    }
  }

  GameLevel _generateLevelWithSeed(int levelNumber, int gridSize, Random random) {
    // Blank grid with no pre-existing blocks at game start
    final initialGrid = List.generate(gridSize, (_) => List<int>.filled(gridSize, 0));
    
    // =========================================================================
    // EXISTING CODE (COMMENTED OUT FOR MENTOR REVIEW):
    // const targetScore = 25000;
    // =========================================================================

    // NEW CODE: Target score scales with level progression & matrix size
    final targetScore = getTargetScoreForLevel(levelNumber, gridSize);
    final targetClears = 10 + (levelNumber > 1 ? (levelNumber ~/ 2) : 0);

    return GameLevel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      targetScore: targetScore,
      targetClears: targetClears,
      initialGrid: initialGrid,
    );
  }
}

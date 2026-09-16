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

  GameLevel _generateInternal(int levelNumber) {
    final random = Random(levelNumber * 7919);
    final gridSize = 8;
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

  GameLevel _generateLevelWithSeed(int levelNumber, int gridSize, Random random) {
    // Blank grid with no pre-existing blocks at game start
    final initialGrid = List.generate(gridSize, (_) => List<int>.filled(gridSize, 0));
    
    // Target score set to 25000 to complete the level/game
    const targetScore = 25000;
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

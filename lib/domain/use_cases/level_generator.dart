import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:block_bloom/domain/models/board_template.dart';
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

  /// Calculates matrix grid size based on level progression & active template
  static int getGridSizeForLevel(int levelNumber) {
    if (levelNumber <= 0) return 8;
    final template = BoardTemplate.getTemplateForLevel(levelNumber);
    return template.rows;
  }

  GameLevel _generateInternal(int levelNumber) {
    final random = Random(levelNumber * 7919);
    final template = BoardTemplate.getTemplateForLevel(levelNumber);
    final gridSize = template.rows;
    return _generateLevelWithSeed(levelNumber, gridSize, random, template: template);
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
    final template = BoardTemplate.getDailyTemplate(date);
    return _generateLevelWithSeed(-99, template.rows, random, template: template);
  }

  /// Calculates target completion score based on level progression & matrix size.
  static int getTargetScoreForLevel(int levelNumber, int gridSize) {
    if (levelNumber <= 0) return 3000;

    if (levelNumber == 1) {
      return 1000;
    } else if (levelNumber == 2) {
      return 1500;
    } else if (levelNumber == 3) {
      return 2500;
    } else if (levelNumber <= 5) {
      return 2500 + ((levelNumber - 3) * 1000);
    } else if (levelNumber <= 9) {
      return 5000 + ((levelNumber - 5) * 1500);
    } else {
      return min(25000, 11000 + ((levelNumber - 9) * 2000));
    }
  }

  GameLevel _generateLevelWithSeed(
    int levelNumber,
    int gridSize,
    Random random, {
    BoardTemplate? template,
  }) {
    final activeTemplate = template ?? (levelNumber > 0 ? BoardTemplate.getTemplateForLevel(levelNumber) : null);
    final actualSize = activeTemplate?.rows ?? gridSize;

    // Build initial grid: 0 for playable cells, -1 for template void/blocked cells
    final initialGrid = List.generate(
      actualSize,
      (r) => List.generate(
        actualSize,
        (c) {
          if (activeTemplate != null && !activeTemplate.isPlayable(r, c)) {
            return -1; // Blocked void space outside template contour
          }
          return 0; // Playable empty space
        },
      ),
    );

    final targetScore = getTargetScoreForLevel(levelNumber, actualSize);
    final targetClears = 10 + (levelNumber > 1 ? (levelNumber ~/ 2) : 0);

    return GameLevel(
      levelNumber: levelNumber,
      gridSize: actualSize,
      targetScore: targetScore,
      targetClears: targetClears,
      initialGrid: initialGrid,
      template: activeTemplate,
    );
  }
}

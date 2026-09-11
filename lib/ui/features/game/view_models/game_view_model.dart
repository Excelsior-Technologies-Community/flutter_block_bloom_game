import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/data/repositories/progress_repository.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/cell_state.dart';
import 'package:block_bloom/domain/models/game_level.dart';
import 'package:block_bloom/domain/use_cases/block_blast_rules.dart';
import 'package:block_bloom/domain/use_cases/level_generator.dart';

class GameViewModelState {
  final GameLevel? level;
  final List<List<BoardCell>> board;
  final List<BlockShape?> availablePieces;
  final List<int> pieceColors;
  final int score;
  final int comboCount;
  final int totalClears;
  final bool isComplete;
  final bool isGameOver;
  final bool isLoading;
  final bool isRandomMode;
  final bool isDailyMode;
  final String? randomDifficulty;
  final String? error;

  // Flower Pools & Powers (GDD Thresholds: 3 Sun, 3 Blue, 5 Red)
  final int sunflowerPool; // 0..3 (3 grants 2x Boost on next clear)
  final bool sunflowerBoostActive; // Whether 2x Boost is ready for next line clear
  final int blueFlowerPool; // 0..3 (3 grants 1 Refresh charge)
  final int blueRefreshCharges; // Available tray refresh charges
  final int redFlowerPool; // 0..5 (5 spawns 1x1 Bloom Bomb piece in tray)

  final int sessionFlowersEarned;
  final bool canContinue; // 1-time continuation per game after Game Over

  final int lastClearedLines;
  final int lastMoveScore;

  final Set<int> clearingRows;
  final Set<int> clearingCols;
  final Set<String> bombClearedCells;
  final bool isAnimating;

  GameViewModelState({
    this.level,
    this.board = const [],
    this.availablePieces = const [],
    this.pieceColors = const [],
    this.score = 0,
    this.comboCount = 0,
    this.totalClears = 0,
    this.isComplete = false,
    this.isGameOver = false,
    this.isLoading = false,
    this.isRandomMode = false,
    this.isDailyMode = false,
    this.randomDifficulty,
    this.error,
    this.sunflowerPool = 0,
    this.sunflowerBoostActive = false,
    this.blueFlowerPool = 0,
    this.blueRefreshCharges = 1, // 1 complimentary refresh at start
    this.redFlowerPool = 0,
    this.sessionFlowersEarned = 0,
    this.canContinue = true,
    this.lastClearedLines = 0,
    this.lastMoveScore = 0,
    this.clearingRows = const {},
    this.clearingCols = const {},
    this.bombClearedCells = const {},
    this.isAnimating = false,
  });

  int get scoreMultiplier => sunflowerBoostActive ? 2 : 1;

  GameViewModelState copyWith({
    GameLevel? level,
    List<List<BoardCell>>? board,
    List<BlockShape?>? availablePieces,
    List<int>? pieceColors,
    int? score,
    int? comboCount,
    int? totalClears,
    bool? isComplete,
    bool? isGameOver,
    bool? isLoading,
    bool? isRandomMode,
    bool? isDailyMode,
    String? randomDifficulty,
    String? error,
    int? sunflowerPool,
    bool? sunflowerBoostActive,
    int? blueFlowerPool,
    int? blueRefreshCharges,
    int? redFlowerPool,
    int? sessionFlowersEarned,
    bool? canContinue,
    int? lastClearedLines,
    int? lastMoveScore,
    Set<int>? clearingRows,
    Set<int>? clearingCols,
    Set<String>? bombClearedCells,
    bool? isAnimating,
  }) {
    return GameViewModelState(
      level: level ?? this.level,
      board: board ?? this.board,
      availablePieces: availablePieces ?? this.availablePieces,
      pieceColors: pieceColors ?? this.pieceColors,
      score: score ?? this.score,
      comboCount: comboCount ?? this.comboCount,
      totalClears: totalClears ?? this.totalClears,
      isComplete: isComplete ?? this.isComplete,
      isGameOver: isGameOver ?? this.isGameOver,
      isLoading: isLoading ?? this.isLoading,
      isRandomMode: isRandomMode ?? this.isRandomMode,
      isDailyMode: isDailyMode ?? this.isDailyMode,
      randomDifficulty: randomDifficulty ?? this.randomDifficulty,
      error: error,
      sunflowerPool: sunflowerPool ?? this.sunflowerPool,
      sunflowerBoostActive: sunflowerBoostActive ?? this.sunflowerBoostActive,
      blueFlowerPool: blueFlowerPool ?? this.blueFlowerPool,
      blueRefreshCharges: blueRefreshCharges ?? this.blueRefreshCharges,
      redFlowerPool: redFlowerPool ?? this.redFlowerPool,
      sessionFlowersEarned: sessionFlowersEarned ?? this.sessionFlowersEarned,
      canContinue: canContinue ?? this.canContinue,
      lastClearedLines: lastClearedLines ?? this.lastClearedLines,
      lastMoveScore: lastMoveScore ?? this.lastMoveScore,
      clearingRows: clearingRows ?? this.clearingRows,
      clearingCols: clearingCols ?? this.clearingCols,
      bombClearedCells: bombClearedCells ?? this.bombClearedCells,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

class GameViewModel extends StateNotifier<GameViewModelState> {
  GameViewModel({
    required this.progressRepository,
    required this.levelGenerator,
  }) : super(GameViewModelState());

  final ProgressRepository progressRepository;
  final LevelGenerator levelGenerator;

  void loadLevel(int levelNumber) {
    state = state.copyWith(isLoading: true);
    try {
      final level = levelGenerator.generate(levelNumber);
      _setupLevel(level, isRandom: false, isDaily: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load level: $e');
    }
  }

  void loadRandomLevel(String difficulty) {
    state = state.copyWith(isLoading: true);
    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final level = levelGenerator.generateRandom(gridSize: 8, seed: seed);
      _setupLevel(level, isRandom: true, isDaily: false, difficulty: difficulty);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate level: $e');
    }
  }

  void loadDailyLevel() {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now().toUtc();
      final level = levelGenerator.generateDaily(now);
      _setupLevel(level, isRandom: false, isDaily: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate daily puzzle: $e');
    }
  }

  void _setupLevel(GameLevel level, {required bool isRandom, required bool isDaily, String? difficulty}) {
    final board = List.generate(
      level.gridSize,
      (r) => List.generate(
        level.gridSize,
        (c) {
          final val = level.initialGrid[r][c];
          if (val > 0) {
            return BoardCell(type: CellType.occupied, colorIndex: val);
          }
          return BoardCell.empty;
        },
      ),
    );

    final pieces = _generate3Pieces();
    final colors = _generate3Colors();

    state = GameViewModelState(
      level: level,
      board: board,
      availablePieces: pieces,
      pieceColors: colors,
      score: 0,
      comboCount: 0,
      totalClears: 0,
      isComplete: false,
      isGameOver: false,
      isLoading: false,
      isRandomMode: isRandom,
      isDailyMode: isDaily,
      randomDifficulty: difficulty,
      sunflowerPool: 0,
      sunflowerBoostActive: false,
      blueFlowerPool: 0,
      blueRefreshCharges: 1, // Start with 1 complimentary refresh
      redFlowerPool: 0,
      sessionFlowersEarned: 0,
      canContinue: true,
    );
  }

  List<BlockShape> _generate3Pieces() {
    final random = Random();
    return List.generate(3, (_) {
      return BlockShape.allShapes[random.nextInt(BlockShape.allShapes.length)];
    });
  }

  List<int> _generate3Colors() {
    final random = Random();
    return List.generate(3, (_) => random.nextInt(8));
  }

  // --- FLOWER POWERS & REFRESH ---

  bool triggerBlueRefresh() {
    if (state.blueRefreshCharges <= 0 || state.isAnimating) return false;

    final freshPieces = _generate3Pieces();
    final freshColors = _generate3Colors();

    state = state.copyWith(
      availablePieces: freshPieces,
      pieceColors: freshColors,
      blueRefreshCharges: state.blueRefreshCharges - 1,
    );
    return true;
  }

  bool useContinue() {
    if (!state.canContinue || !state.isGameOver) return false;

    final freshPieces = _generate3Pieces();
    final freshColors = _generate3Colors();

    state = state.copyWith(
      availablePieces: freshPieces,
      pieceColors: freshColors,
      isGameOver: false,
      canContinue: false,
    );
    return true;
  }

  // --- PIECE PLACEMENT & BOMB DETONATION LOGIC ---

  bool placePiece(int pieceIndex, int startRow, int startCol) {
    if (state.isComplete || state.isGameOver || state.isAnimating) return false;

    final piece = state.availablePieces[pieceIndex];
    if (piece == null) return false;

    if (!BlockBlastRules.canPlacePiece(state.board, piece, startRow, startCol)) {
      return false;
    }

    final n = state.board.length;

    // Handle 💣 Bloom Bomb piece placement!
    if (piece.isBomb) {
      return _detonateBombPiece(pieceIndex, startRow, startCol);
    }

    final newBoard = List.generate(
      n,
      (r) => List<BoardCell>.from(state.board[r]),
    );

    final colorIdx = state.pieceColors[pieceIndex] + 1;
    int placedBlocks = 0;

    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.matrix[r][c] == 1) {
          newBoard[startRow + r][startCol + c] = BoardCell(
            type: CellType.occupied,
            colorIndex: colorIdx,
          );
          placedBlocks++;
        }
      }
    }

    final completedRows = BlockBlastRules.getCompletedRows(newBoard);
    final completedCols = BlockBlastRules.getCompletedCols(newBoard);

    final clearedLines = completedRows.length + completedCols.length;
    int currentCombo = state.comboCount;

    if (clearedLines > 0) {
      currentCombo += 1;
    } else {
      currentCombo = 0;
    }

    final rawLinePoints = BlockBlastRules.getLineClearPoints(clearedLines);
    final comboMult = BlockBlastRules.getComboMultiplier(currentCombo);
    final baseMoveScore = (placedBlocks * 10) + (rawLinePoints * comboMult).toInt();

    // Check Sunflower 2x Boost
    final moveScore = baseMoveScore * state.scoreMultiplier;
    final newScore = state.score + moveScore;
    bool nextSunBoost = state.sunflowerBoostActive;
    if (clearedLines > 0 && nextSunBoost) {
      nextSunBoost = false; // Consumed 2x boost on line clear
    }

    final newPieces = List<BlockShape?>.from(state.availablePieces);
    newPieces[pieceIndex] = null;

    final newPieceColors = List<int>.from(state.pieceColors);

    if (newPieces.every((p) => p == null)) {
      final freshPieces = _generate3Pieces();
      final freshColors = _generate3Colors();
      for (int i = 0; i < 3; i++) {
        newPieces[i] = freshPieces[i];
        newPieceColors[i] = freshColors[i];
      }
    }

    final newTotalClears = state.totalClears + clearedLines;

    bool isComplete = false;
    final level = state.level;
    if (level != null && !state.isRandomMode && !state.isDailyMode) {
      if (newScore >= level.targetScore || newTotalClears >= level.targetClears) {
        isComplete = true;
      }
    }

    if (clearedLines > 0) {
      AudioService.instance.playClearSound();
      state = state.copyWith(
        board: newBoard,
        availablePieces: newPieces,
        pieceColors: newPieceColors,
        score: newScore,
        comboCount: currentCombo,
        totalClears: newTotalClears,
        isComplete: false,
        isGameOver: false,
        sunflowerBoostActive: nextSunBoost,
        lastClearedLines: clearedLines,
        lastMoveScore: moveScore,
        clearingRows: completedRows.toSet(),
        clearingCols: completedCols.toSet(),
        isAnimating: true,
      );

      Timer(const Duration(milliseconds: 380), () {
        final clearedBoard = List.generate(
          n,
          (r) => List<BoardCell>.from(newBoard[r]),
        );

        int sunPool = state.sunflowerPool;
        int bluePool = state.blueFlowerPool;
        int redPool = state.redFlowerPool;
        int refreshCharges = state.blueRefreshCharges;
        bool sunBoost = state.sunflowerBoostActive;
        int flowersEarned = state.sessionFlowersEarned;

        final random = Random();
        final flowerTypes = FlowerType.values;
        final occupiedCoords = <Point<int>>[];
        int bloomBonusPoints = 0;

        void processClearedCell(int r, int c) {
          final cell = clearedBoard[r][c];
          if (cell.type == CellType.occupied) {
            occupiedCoords.add(Point(r, c));
            clearedBoard[r][c] = BoardCell.empty;
          } else if (cell.type == CellType.bloom) {
            // Sprout grows into a mature flower! +150 bonus
            final fType = flowerTypes[random.nextInt(flowerTypes.length)];
            clearedBoard[r][c] = BoardCell(type: CellType.flower, flowerType: fType);
            bloomBonusPoints += 150;
          } else if (cell.type == CellType.flower) {
            // Harvest mature flower! +250 bonus
            bloomBonusPoints += 250;
            flowersEarned++;
            progressRepository.addFlowers(1);

            if (cell.flowerType == FlowerType.sunflower) {
              sunPool++;
              if (sunPool >= 3) {
                sunPool = 0;
                sunBoost = true; // 2x Boost ready!
              }
            } else if (cell.flowerType == FlowerType.blueFlower) {
              bluePool++;
              if (bluePool >= 3) {
                bluePool = 0;
                refreshCharges++; // 1 Refresh added!
              }
            } else if (cell.flowerType == FlowerType.redFlower) {
              redPool++;
              if (redPool >= 5) {
                redPool = 0;
                // Spawn 1x1 Bomb piece into available tray slot!
                for (int i = 0; i < 3; i++) {
                  if (newPieces[i] == null) {
                    newPieces[i] = BlockShape.bomb;
                    break;
                  }
                }
              }
            }
            clearedBoard[r][c] = BoardCell.empty;
          }
        }

        for (final r in completedRows) {
          for (int c = 0; c < n; c++) {
            processClearedCell(r, c);
          }
        }
        for (final c in completedCols) {
          for (int r = 0; r < n; r++) {
            if (completedRows.contains(r)) continue;
            processClearedCell(r, c);
          }
        }

        if (occupiedCoords.isNotEmpty) {
          final sproutCoord = occupiedCoords[random.nextInt(occupiedCoords.length)];
          clearedBoard[sproutCoord.x][sproutCoord.y] = const BoardCell(type: CellType.bloom);
        }

        final updatedScore = state.score + bloomBonusPoints;

        bool isGameOver = false;
        if (!isComplete && !BlockBlastRules.canAnyPieceBePlaced(clearedBoard, newPieces)) {
          isGameOver = true;
        }

        if (state.isDailyMode && isGameOver) {
          final now = DateTime.now().toUtc();
          final dateStr = '${now.year}-${now.month}-${now.day}';
          progressRepository.saveDailyScore(updatedScore, dateStr);
        }

        state = state.copyWith(
          board: clearedBoard,
          score: updatedScore,
          availablePieces: newPieces,
          sunflowerPool: sunPool,
          sunflowerBoostActive: sunBoost,
          blueFlowerPool: bluePool,
          blueRefreshCharges: refreshCharges,
          redFlowerPool: redPool,
          sessionFlowersEarned: flowersEarned,
          isComplete: isComplete,
          isGameOver: isGameOver,
          clearingRows: const {},
          clearingCols: const {},
          isAnimating: false,
        );
      });
    } else {
      AudioService.instance.playBlockPlaceSound();
      bool isGameOver = false;
      if (!isComplete && !BlockBlastRules.canAnyPieceBePlaced(newBoard, newPieces)) {
        isGameOver = true;
      }

      if (state.isDailyMode && isGameOver) {
        final now = DateTime.now().toUtc();
        final dateStr = '${now.year}-${now.month}-${now.day}';
        progressRepository.saveDailyScore(newScore, dateStr);
      }

      state = state.copyWith(
        board: newBoard,
        availablePieces: newPieces,
        pieceColors: newPieceColors,
        score: newScore,
        comboCount: currentCombo,
        totalClears: newTotalClears,
        isComplete: isComplete,
        isGameOver: isGameOver,
        sunflowerBoostActive: nextSunBoost,
        lastClearedLines: clearedLines,
        lastMoveScore: moveScore,
        isAnimating: true,
      );

      Timer(const Duration(milliseconds: 150), () {
        state = state.copyWith(isAnimating: false);
      });
    }

    return true;
  }

  bool _detonateBombPiece(int pieceIndex, int centerRow, int centerCol) {
    final n = state.board.length;
    final newBoard = List.generate(
      n,
      (r) => List<BoardCell>.from(state.board[r]),
    );

    final affected = <String>{};
    int bonusPoints = 0;
    int flowersEarned = state.sessionFlowersEarned;
    int sunPool = state.sunflowerPool;
    int bluePool = state.blueFlowerPool;
    int redPool = state.redFlowerPool;
    int refreshCharges = state.blueRefreshCharges;
    bool sunBoost = state.sunflowerBoostActive;

    final random = Random();
    final flowerTypes = FlowerType.values;
    final occupiedCoords = <Point<int>>[];

    for (int r = max(0, centerRow - 1); r <= min(n - 1, centerRow + 1); r++) {
      for (int c = max(0, centerCol - 1); c <= min(n - 1, centerCol + 1); c++) {
        final cell = newBoard[r][c];
        if (cell.type != CellType.empty) {
          affected.add('$r,$c');

          if (cell.type == CellType.occupied) {
            occupiedCoords.add(Point(r, c));
            newBoard[r][c] = BoardCell.empty;
            bonusPoints += 50;
          } else if (cell.type == CellType.bloom) {
            final fType = flowerTypes[random.nextInt(flowerTypes.length)];
            newBoard[r][c] = BoardCell(type: CellType.flower, flowerType: fType);
            bonusPoints += 100;
          } else if (cell.type == CellType.flower) {
            flowersEarned++;
            progressRepository.addFlowers(1);

            if (cell.flowerType == FlowerType.sunflower) {
              sunPool++;
              if (sunPool >= 3) {
                sunPool = 0;
                sunBoost = true;
              }
            } else if (cell.flowerType == FlowerType.blueFlower) {
              bluePool++;
              if (bluePool >= 3) {
                bluePool = 0;
                refreshCharges++;
              }
            } else if (cell.flowerType == FlowerType.redFlower) {
              redPool++;
            }
            newBoard[r][c] = BoardCell.empty;
            bonusPoints += 250;
          }
        }
      }
    }

    if (occupiedCoords.isNotEmpty) {
      final sproutCoord = occupiedCoords[random.nextInt(occupiedCoords.length)];
      newBoard[sproutCoord.x][sproutCoord.y] = const BoardCell(type: CellType.bloom);
    }

    final totalBonus = bonusPoints * state.scoreMultiplier;
    final newPieces = List<BlockShape?>.from(state.availablePieces);
    newPieces[pieceIndex] = null;

    if (newPieces.every((p) => p == null)) {
      final freshPieces = _generate3Pieces();
      final freshColors = _generate3Colors();
      for (int i = 0; i < 3; i++) {
        newPieces[i] = freshPieces[i];
        state.pieceColors[i] = freshColors[i];
      }
    }

    state = state.copyWith(
      board: newBoard,
      score: state.score + totalBonus,
      availablePieces: newPieces,
      sunflowerPool: sunPool,
      sunflowerBoostActive: sunBoost,
      blueFlowerPool: bluePool,
      blueRefreshCharges: refreshCharges,
      redFlowerPool: redPool,
      sessionFlowersEarned: flowersEarned,
      bombClearedCells: affected,
      isAnimating: true,
      lastMoveScore: totalBonus,
    );

    Timer(const Duration(milliseconds: 350), () {
      bool isGameOver = false;
      if (!state.isComplete && !BlockBlastRules.canAnyPieceBePlaced(newBoard, newPieces)) {
        isGameOver = true;
      }
      state = state.copyWith(
        bombClearedCells: const {},
        isAnimating: false,
        isGameOver: isGameOver,
      );
    });

    return true;
  }

  void resetLevel() {
    if (state.level != null) {
      _setupLevel(state.level!, isRandom: state.isRandomMode, isDaily: state.isDailyMode, difficulty: state.randomDifficulty);
    }
  }

  Future<void> completeLevel() async {
    if (state.level != null && !state.isRandomMode && !state.isDailyMode) {
      await progressRepository.saveLevelCompletion(
        levelNumber: state.level!.levelNumber,
        score: state.score,
        elapsedSeconds: 0,
      );
    }
  }
}

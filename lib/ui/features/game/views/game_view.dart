import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/domain/models/cell_state.dart';
import 'package:block_bloom/domain/models/game_level.dart';
import 'package:block_bloom/domain/use_cases/block_blast_rules.dart';
import 'package:block_bloom/ui/core/theme/app_colors.dart';
import 'package:block_bloom/ui/core/widgets/tangible_button.dart';
import 'package:block_bloom/ui/features/game/view_models/game_view_model.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/features/game/widgets/pause_dialog.dart';
import 'package:block_bloom/ui/features/game/widgets/game_over_dialog.dart';
import 'package:block_bloom/ui/features/daily_garden/views/daily_garden_game_over_view.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.levelNumber,
    this.isRandom = false,
    this.isDaily = false,
    this.randomDifficulty = 'Easy',
  });

  final int levelNumber;
  final bool isRandom;
  final bool isDaily;
  final String randomDifficulty;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  int? _selectedPieceIndex;
  int? _hoveredPieceIndex;
  int? _hoveredStartRow;
  int? _hoveredStartCol;

  final ShakeController _shakeController = ShakeController();
  final GlobalKey _gridKey = GlobalKey();

  void _updateHoverFromTouch(Offset globalPosition, BlockShape piece, double touchOffsetY) {
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final gridLocal = renderBox.globalToLocal(globalPosition);
    final pieceLocalY = gridLocal.dy - touchOffsetY;
    final pieceLocalX = gridLocal.dx;

    final gridWidth = renderBox.size.width - 12; // Accounting for 6px padding on left & right
    final level = ref.read(gameViewModelProvider).level;
    if (level == null) return;

    final cellSize = gridWidth / level.gridSize;

    // Calculate top-left cell index based on piece dimensions
    int targetR = ((pieceLocalY - (cellSize * (piece.rows - 1) / 2)) / cellSize).round();
    int targetC = ((pieceLocalX - (cellSize * (piece.cols - 1) / 2)) / cellSize).round();

    if (targetR >= -1 && targetR <= level.gridSize && targetC >= -1 && targetC <= level.gridSize) {
      targetR = targetR.clamp(0, level.gridSize - piece.rows);
      targetC = targetC.clamp(0, level.gridSize - piece.cols);
      if (_hoveredStartRow != targetR || _hoveredStartCol != targetC) {
        setState(() {
          _hoveredStartRow = targetR;
          _hoveredStartCol = targetC;
        });
      }
    } else {
      if (_hoveredStartRow != null || _hoveredStartCol != null) {
        setState(() {
          _hoveredStartRow = null;
          _hoveredStartCol = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.isDaily) {
        ref.read(gameViewModelProvider.notifier).loadDailyLevel();
      } else if (widget.isRandom) {
        ref.read(gameViewModelProvider.notifier).loadRandomLevel(widget.randomDifficulty);
      } else {
        ref.read(gameViewModelProvider.notifier).loadLevel(widget.levelNumber);
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameViewModelProvider);

    ref.listen<GameViewModelState>(gameViewModelProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _onLevelComplete(next);
      } else if (next.isGameOver && !(prev?.isGameOver ?? false)) {
        _onGameOver(next);
      } else if (next.lastClearedLines > 0 && next.lastClearedLines != (prev?.lastClearedLines ?? 0)) {
        HapticFeedback.heavyImpact();
        _shakeController.shake();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.gameBg, // Card / Scaffold Background #090027
      body: ShakeWidget(
        controller: _shakeController,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header / Top Navigation Bar
                  _buildTopBar(context, state),

                  // Power Threshold Bar (Optional Booster info)
                  _buildGardenPowerBar(state),

                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC800)))
                        : state.error != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => ref
                                          .read(gameViewModelProvider.notifier)
                                          .resetLevel(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _buildGame(state),
                  ),
                ],
              ),

              // Bottom Right Floating Flower / Score Union Pill Badge (#001834 background + game_leaf)
              Positioned(
                bottom: 12,
                right: 16,
                child: _buildBottomFlowerBadge(state.sessionFlowersEarned > 0 ? state.sessionFlowersEarned : 125),
              ),

              // Floating Score, Combo & Curved "LINE CLEAR!" Overlay
              FloatingScoreOverlay(
                lastScore: state.lastMoveScore,
                combo: state.comboCount,
                clearedLines: state.lastClearedLines,
              ),

              ConfettiExplosion(trigger: state.isComplete),

              if (state.isGameOver)
                Positioned.fill(
                  child: widget.isDaily
                      ? DailyGardenGameOverView(
                          onHome: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        )
                      : GameOverView(
                          onPlayAgain: () {
                            ref.read(gameViewModelProvider.notifier).resetLevel();
                          },
                          onHome: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TOP BAR HEADER ---
  Widget _buildTopBar(BuildContext context, GameViewModelState state) {
    const displayTarget = 25000;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: Pause Button
          Align(
            alignment: Alignment.centerLeft,
            child: _buildPauseButton(context),
          ),

          // Center SCORE Header (Pill badge with gold border, leaf on left & right, score below)
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Center SCORE Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001834),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFC800),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          'SCORE',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Left Leaf (Mirrored to sprout outward to top-left)
                    Positioned(
                      left: -14,
                      top: -2,
                      child: Transform.scale(
                        scaleX: -1,
                        child: Transform.rotate(
                          angle: 0.15,
                          child: Image.asset(
                            widget.isDaily ? 'assets/garden_leaf.png' : 'assets/leaf.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),

                    // Right Leaf (Sprouting outward to top-right)
                    Positioned(
                      right: -14,
                      top: -2,
                      child: Transform.rotate(
                        angle: -0.15,
                        child: Image.asset(
                          widget.isDaily ? 'assets/garden_leaf2.png' : 'assets/leaf.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    _formatScore(state.score),
                    style: GoogleFonts.chakraPetch(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Target Crown Badge
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/score.png',
                  width: 22,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, st) => const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFC800),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    _formatScore(displayTarget),
                    style: GoogleFonts.chakraPetch(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Circular Pause Button with game_leaf attached at bottom right
  Widget _buildPauseButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            AudioService.instance.playClickSound();
            showDialog(
              context: context,
              barrierDismissible: true,
              barrierColor: Colors.transparent,
              builder: (context) => const PauseDialog(),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF001834),
              border: Border.all(
                color: const Color(0xFFFFC800),
                width: 1.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.pause_rounded,
                color: Color(0xFFFFC800),
                size: 24,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -3,
          right: -4,
          child: Image.asset(
            'assets/leaf.png',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // Bottom Right Flower / Score Badge (#001834 background + game_flower + leaf)
  Widget _buildBottomFlowerBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF001834),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFC800),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  '$count',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(
                'assets/game_flower.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/small_flower.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx2, err2, st2) => const Text('🌸', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -3,
          right: -4,
          child: Image.asset(
            'assets/leaf.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  String _formatScore(int score) {
    final str = score.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // Optional Power / Garden Threshold Bar
  Widget _buildGardenPowerBar(GameViewModelState state) {
    if (state.sunflowerPool == 0 && state.blueFlowerPool == 0 && state.redFlowerPool == 0 && !state.sunflowerBoostActive) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(gameViewModelProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF001834),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF007AFF),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (state.sunflowerBoostActive || state.sunflowerPool > 0)
            Row(
              children: [
                const Text('🌻', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  state.sunflowerBoostActive ? '2X BOOST!' : '${state.sunflowerPool}/3',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFC800),
                  ),
                ),
              ],
            ),
          if (state.blueRefreshCharges > 0)
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                notifier.triggerBlueRefresh();
              },
              child: Row(
                children: [
                  const Text('🪻', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh (${state.blueRefreshCharges})',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- MAIN GAME VIEW ---
  Widget _buildGame(GameViewModelState state) {
    final level = state.level;
    if (level == null) return const SizedBox.shrink();

    final activePieceIndex = _hoveredPieceIndex ?? _selectedPieceIndex;
    final activePiece = (activePieceIndex != null && activePieceIndex < state.availablePieces.length) ? state.availablePieces[activePieceIndex] : null;
    final activeColorIndex = (activePieceIndex != null && activePieceIndex < state.pieceColors.length) ? state.pieceColors[activePieceIndex] + 1 : 1;

    bool isValidPlacement = false;
    final Set<String> previewCells = {};
    final Set<int> glowingRows = {};
    final Set<int> glowingCols = {};

    if (activePiece != null && _hoveredStartRow != null && _hoveredStartCol != null) {
      isValidPlacement = BlockBlastRules.canPlacePiece(
        state.board,
        activePiece,
        _hoveredStartRow!,
        _hoveredStartCol!,
      );

      if (!activePiece.isBomb) {
        for (int r = 0; r < activePiece.rows; r++) {
          for (int c = 0; c < activePiece.cols; c++) {
            if (activePiece.matrix[r][c] == 1) {
              final targetR = _hoveredStartRow! + r;
              final targetC = _hoveredStartCol! + c;
              if (targetR >= 0 && targetR < level.gridSize && targetC >= 0 && targetC < level.gridSize) {
                previewCells.add('$targetR,$targetC');
              }
            }
          }
        }

        if (isValidPlacement) {
          final simulatedBoard = List.generate(
            level.gridSize,
            (r) => List<BoardCell>.from(state.board[r]),
          );
          for (int r = 0; r < activePiece.rows; r++) {
            for (int c = 0; c < activePiece.cols; c++) {
              if (activePiece.matrix[r][c] == 1) {
                simulatedBoard[_hoveredStartRow! + r][_hoveredStartCol! + c] = BoardCell(
                  type: CellType.occupied,
                  colorIndex: activeColorIndex,
                );
              }
            }
          }
          glowingRows.addAll(BlockBlastRules.getCompletedRows(simulatedBoard));
          glowingCols.addAll(BlockBlastRules.getCompletedCols(simulatedBoard));
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      key: _gridKey,
                      decoration: BoxDecoration(
                        color: const Color(0xFF090027),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF007AFF),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: level.gridSize,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                        itemCount: level.gridSize * level.gridSize,
                        itemBuilder: (context, index) {
                          final r = index ~/ level.gridSize;
                          final c = index % level.gridSize;
                          final cell = state.board[r][c];
                          final isPreviewCell = previewCells.contains('$r,$c');
                          final isLineGlowing = glowingRows.contains(r) || glowingCols.contains(c);
                          final isBombAffected = state.bombClearedCells.contains('$r,$c');

                          bool isBombHovered = false;
                          if (activePiece != null && activePiece.isBomb && _hoveredStartRow != null && _hoveredStartCol != null) {
                            if ((r - _hoveredStartRow!).abs() <= 1 && (c - _hoveredStartCol!).abs() <= 1) {
                              isBombHovered = true;
                            }
                          }

                          return DragTarget<int>(
                            onWillAcceptWithDetails: (details) {
                              setState(() {
                                _hoveredPieceIndex = details.data;
                                _hoveredStartRow = r;
                                _hoveredStartCol = c;
                              });
                              return true;
                            },
                            onLeave: (data) {},
                            onAcceptWithDetails: (details) {
                              final pIdx = details.data;
                              if (_hoveredStartRow != null && _hoveredStartCol != null) {
                                ref
                                    .read(gameViewModelProvider.notifier)
                                    .placePiece(pIdx, _hoveredStartRow!, _hoveredStartCol!);
                              } else {
                                ref
                                    .read(gameViewModelProvider.notifier)
                                    .placePiece(pIdx, r, c);
                              }
                              setState(() {
                                _selectedPieceIndex = null;
                                _hoveredPieceIndex = null;
                                _hoveredStartRow = null;
                                _hoveredStartCol = null;
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              Widget cellWidget = _buildCellContent(
                                cell: cell,
                                r: r,
                                c: c,
                                isPreviewCell: isPreviewCell,
                                isValidPlacement: isValidPlacement,
                                activeColorIndex: activeColorIndex,
                                isLineGlowing: isLineGlowing,
                                isBombHovered: isBombHovered,
                                isBombAffected: isBombAffected,
                                state: state,
                              );

                              return MouseRegion(
                                onEnter: (_) {
                                  setState(() {
                                    _hoveredStartRow = r;
                                    _hoveredStartCol = c;
                                  });
                                },
                                onExit: (_) {
                                  if (_hoveredStartRow == r && _hoveredStartCol == c) {
                                    setState(() {
                                      _hoveredStartRow = null;
                                      _hoveredStartCol = null;
                                    });
                                  }
                                },
                                child: InkWell(
                                  onTap: () {
                                    final notifier = ref.read(gameViewModelProvider.notifier);
                                    if (_selectedPieceIndex != null) {
                                      final placed = notifier.placePiece(_selectedPieceIndex!, r, c);
                                      if (placed) {
                                        setState(() {
                                          _selectedPieceIndex = null;
                                          _hoveredStartRow = null;
                                          _hoveredStartCol = null;
                                        });
                                      }
                                    }
                                  },
                                  child: cellWidget,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Available Pieces Tray Container (#001834 slots)
            Container(
              height: math.min(constraints.maxHeight * 0.22, 125.0),
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 56),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF090027),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0A3975),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (pIdx) {
                  final piece = pIdx < state.availablePieces.length ? state.availablePieces[pIdx] : null;
                  if (piece == null) return const Expanded(child: SizedBox.shrink());

                  final colorIdx = pIdx < state.pieceColors.length ? state.pieceColors[pIdx] + 1 : 1;
                  final isSelected = _selectedPieceIndex == pIdx;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001834),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFC800) : const Color(0xFF103975),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFC800).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: LayoutBuilder(
                        builder: (context, pieceBox) {
                          final maxScaleW = (pieceBox.maxWidth - 16) / piece.cols - 2.0;
                          final maxScaleH = (pieceBox.maxHeight - 16) / piece.rows - 2.0;
                          final blockSize = math.max(8.0, math.min(22.0, math.min(maxScaleW, maxScaleH)));

                          final gridWidth = (constraints.maxWidth - 44);
                          final gridCellSize = gridWidth / level.gridSize;

                          return Center(
                            child: Draggable<int>(
                              data: pIdx,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              onDragStarted: () {
                                AudioService.instance.playClickSound();
                                setState(() {
                                  _selectedPieceIndex = pIdx;
                                  _hoveredPieceIndex = pIdx;
                                });
                              },
                              onDragUpdate: (details) {
                                _updateHoverFromTouch(details.globalPosition, piece, 60.0);
                              },
                              onDragEnd: (details) {
                                if (_hoveredPieceIndex != null && _hoveredStartRow != null && _hoveredStartCol != null) {
                                  final notifier = ref.read(gameViewModelProvider.notifier);
                                  notifier.placePiece(_hoveredPieceIndex!, _hoveredStartRow!, _hoveredStartCol!);
                                }
                                setState(() {
                                  _selectedPieceIndex = null;
                                  _hoveredPieceIndex = null;
                                  _hoveredStartRow = null;
                                  _hoveredStartCol = null;
                                });
                              },
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.translate(
                                  offset: const Offset(0, -60),
                                  child: Transform.scale(
                                    scale: 1.05,
                                    child: _buildPiecePreview(piece, colorIdx, scale: gridCellSize),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.15,
                                child: _buildPiecePreview(piece, colorIdx, scale: blockSize),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  AudioService.instance.playClickSound();
                                  setState(() {
                                    _selectedPieceIndex = isSelected ? null : pIdx;
                                  });
                                },
                                child: _buildPiecePreview(piece, colorIdx, scale: blockSize),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  // Translucent Ghost Target Slot Guide (Eliminates double-block visual confusion!)
  Widget _buildGhostBlock(Color blockColor) {
    return Container(
      decoration: BoxDecoration(
        color: blockColor.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: blockColor.withValues(alpha: 0.35),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // Cell Content Rendering with bright block PNG images from assets/blocks/
  Widget _buildCellContent({
    required BoardCell cell,
    required int r,
    required int c,
    required bool isPreviewCell,
    required bool isValidPlacement,
    required int activeColorIndex,
    required bool isLineGlowing,
    required bool isBombHovered,
    required bool isBombAffected,
    required GameViewModelState state,
  }) {
    final isClearing = state.clearingRows.contains(r) || state.clearingCols.contains(c) || isBombAffected;
    final blockColor = AppColors.blockColors[(activeColorIndex - 1) % AppColors.blockColors.length];

    if (cell.type == CellType.occupied) {
      final block = _buildBlockAsset(cell.colorIndex);
      if (isClearing) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * math.pi * 2,
              child: Transform.scale(
                scale: (1.0 - value).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: block,
        );
      }
      return block;
    } else if (cell.type == CellType.bloom) {
      // Bloom Sprout Cell 🌱 (Game Leaf) - Glowing Golden Highlight on potential Line Clear!
      return Container(
        decoration: BoxDecoration(
          color: isLineGlowing ? const Color(0xFF1E3A8A) : const Color(0xFF0A2218),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isLineGlowing ? const Color(0xFFFFC800) : const Color(0xFF10B981),
            width: isLineGlowing ? 2.0 : 1.0,
          ),
          boxShadow: isLineGlowing
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFC800).withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Image.asset(
            'assets/game_leaf.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Image.asset(
              'assets/leaf.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (ctx2, err2, st2) => const Text('🌱', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      );
    } else if (cell.type == CellType.flower) {
      // Flower Cell 🌸 - Glowing Golden Highlight on potential Line Clear!
      return Container(
        decoration: BoxDecoration(
          color: isLineGlowing ? const Color(0xFF1E3A8A) : const Color(0xFF1A1A3A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFFFC800),
            width: isLineGlowing ? 2.2 : 1.2,
          ),
          boxShadow: isLineGlowing
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFC800).withValues(alpha: 0.7),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Image.asset(
            'assets/game_flower.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Image.asset(
              'assets/small_flower.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (ctx2, err2, st2) => const Text('🌸', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      );
    } else if (isPreviewCell) {
      if (!isValidPlacement) {
        // Red Invalid Placement Warning Container with X icon
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
          ),
        );
      }
      // Ghost Target Slot Outline (Clean drop zone indicator without duplicate 3D block rendering)
      return _buildGhostBlock(blockColor);
    } else {
      // Empty cell
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isBombHovered
              ? Colors.redAccent.withValues(alpha: 0.3)
              : isLineGlowing
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF050C1E),
          borderRadius: BorderRadius.circular(4),
          border: isBombHovered
              ? Border.all(color: Colors.redAccent, width: 1.5)
              : isLineGlowing
                  ? Border.all(color: const Color(0xFF007AFF), width: 1.0)
                  : Border.all(color: const Color(0xFF0E2248), width: 0.5),
        ),
        child: isBombHovered
            ? const Center(child: Icon(Icons.gps_fixed_rounded, color: Colors.redAccent, size: 16))
            : null,
      );
    }
  }

  // Multi-layered bright rendering of block PNG asset over a vibrant base plate layer
  Widget _buildBlockAsset(int colorIndex, {bool isPreview = false, double borderRadius = 4.0}) {
    final imgIndex = ((colorIndex - 1) % 12) + 1;
    final blockColor = AppColors.blockColors[(colorIndex - 1) % AppColors.blockColors.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Base plate layer underneath to prevent dark background collapse
        color: isPreview ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF1E293B),
        boxShadow: isPreview
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: blockColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Bright Base Plate Gradient Layer to ensure high contrast against dark background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isPreview
                      ? [
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.3),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          blockColor.withValues(alpha: 0.4),
                        ],
                ),
              ),
            ),

            // Layer 2: Main Block PNG Image Asset
            Image.asset(
              'assets/blocks/$imgIndex.png',
              fit: BoxFit.cover,
              opacity: isPreview ? const AlwaysStoppedAnimation(0.85) : null,
              errorBuilder: (context, error, stackTrace) => _buildGlossyBlock(
                blockColor,
                isPreview: isPreview,
              ),
            ),

            // Layer 3: Top Sheen Rim Light Overlay for extra 3D popping brilliance
            if (!isPreview)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiecePreview(BlockShape piece, int colorIndex, {double scale = 18}) {
    if (piece.isBomb) {
      return Container(
        width: scale * 2,
        height: scale * 2,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 2.0),
        ),
        child: const Center(
          child: Text('💣', style: TextStyle(fontSize: 22)),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(piece.rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(piece.cols, (c) {
            final fill = piece.matrix[r][c] == 1;
            if (!fill) {
              return SizedBox(width: scale + 2.0, height: scale + 2.0);
            }
            return Container(
              margin: const EdgeInsets.all(1.0),
              child: SizedBox(
                width: scale,
                height: scale,
                child: _buildBlockAsset(colorIndex),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildGlossyBlock(Color color, {bool isPreview = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: isPreview ? color.withValues(alpha: 0.8) : color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _onLevelComplete(GameViewModelState state) async {
    AudioService.instance.playClearSound();
    await ref.read(gameViewModelProvider.notifier).completeLevel();
    if (!mounted) return;
    _showCompleteDialog(state);
  }

  Future<void> _onGameOver(GameViewModelState state) async {
    if (!mounted) return;
    AudioService.instance.playGameOverSound();
  }

  void _showCompleteDialog(GameViewModelState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF001834),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFC800), width: 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFD97706),
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'LEVEL COMPLETE!',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    TangibleButton(
                      text: state.isRandomMode ? 'Play Again' : 'Next Level',
                      height: 50,
                      onPressed: () {
                        Navigator.pop(context);
                        if (state.isRandomMode) {
                          ref
                              .read(gameViewModelProvider.notifier)
                              .loadRandomLevel(state.randomDifficulty ?? 'Easy');
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameView(
                                levelNumber: widget.levelNumber + 1,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TangibleButton(
                      text: 'Home',
                      isSecondary: true,
                      height: 50,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Confetti Particle System
class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 300.0 * dt;
  }
}

class ConfettiExplosion extends StatefulWidget {
  final bool trigger;
  const ConfettiExplosion({super.key, required this.trigger});

  @override
  State<ConfettiExplosion> createState() => _ConfettiExplosionState();
}

class _ConfettiExplosionState extends State<ConfettiExplosion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(_tick);
  }

  void _tick() {
    final dt = 0.016;
    for (final p in _particles) {
      p.update(dt);
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(ConfettiExplosion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _spawnParticles();
      _controller.forward(from: 0.0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    for (int i = 0; i < 60; i++) {
      _particles.add(
        ConfettiParticle(
          x: 200,
          y: 200,
          vx: (_random.nextDouble() - 0.5) * 400,
          vy: -_random.nextDouble() * 400 - 100,
          size: 6 + _random.nextDouble() * 6,
          color: AppColors.blockColors[_random.nextInt(AppColors.blockColors.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();
    return CustomPaint(
      painter: _ConfettiPainter(_particles),
      child: const SizedBox.expand(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

// Floating Score, Combo & Curved "LINE CLEAR!" Overlay
class FloatingScoreOverlay extends StatefulWidget {
  final int lastScore;
  final int combo;
  final int clearedLines;

  const FloatingScoreOverlay({
    super.key,
    required this.lastScore,
    required this.combo,
    required this.clearedLines,
  });

  @override
  State<FloatingScoreOverlay> createState() => _FloatingScoreOverlayState();
}

class _FloatingScoreOverlayState extends State<FloatingScoreOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(_controller);

    if (widget.lastScore > 0 || widget.clearedLines > 0 || widget.combo > 1) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingScoreOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.lastScore > 0 && widget.lastScore != oldWidget.lastScore) ||
        (widget.clearedLines > 0 && widget.clearedLines != oldWidget.clearedLines) ||
        (widget.combo > 1 && widget.combo != oldWidget.combo)) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lastScore <= 0 && widget.clearedLines <= 0 && widget.combo <= 1) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating && _controller.isCompleted) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Center Curved LINE CLEAR! or COMBO 2X Overlay Banner
            Positioned(
              top: MediaQuery.of(context).size.height * 0.33,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.clearedLines > 0) ...[
                          _buildCurvedLineClearText(),
                          const SizedBox(height: 12),
                          // +100 Score callout
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              '+${widget.lastScore > 0 ? widget.lastScore : 100}',
                              style: GoogleFonts.chakraPetch(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF705320),
                                    offset: Offset(2.0, 2.0),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (widget.combo > 1) ...[
                          // Auto-Disappearing Combo Board Banner Popup
                          _buildComboBoardBanner(widget.combo),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Curved LINE CLEAR! Arc Text (Width ~198.79px, Height ~35.68px, -1 deg rotation, gold gradient)
  Widget _buildCurvedLineClearText() {
    const text = 'LINE CLEAR!';
    final total = text.length;

    return Transform.rotate(
      angle: -0.0175, // -1 degree rotation
      child: SizedBox(
        width: 220,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Left Golden Star Sparkles ✨
            Positioned(
              left: -18,
              child: _buildStarSparkles(size: 22),
            ),

            // Curved Letter Arc
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(total, (i) {
                final char = text[i];
                final t = (i - (total - 1) / 2.0) / ((total - 1) / 2.0);
                final dy = (1.0 - (t * t)) * -6.0; // Quadratic upward curve
                final angle = t * 0.10;

                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: angle,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        char,
                        style: GoogleFonts.chakraPetch(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          shadows: const [
                            Shadow(
                              color: Color(0xFF705320),
                              offset: Offset(1.5, 2.0),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Right Golden Star Sparkles ✨
            Positioned(
              right: -18,
              child: _buildStarSparkles(size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarSparkles({double size = 20}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFD700)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: size,
        shadows: const [
          Shadow(
            color: Color(0xFF705320),
            blurRadius: 4,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  // Combo Board Banner Overlay matching attached screenshot
  Widget _buildComboBoardBanner(int comboCount) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/combo_board.png',
          width: 170,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, st) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF814D00),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFC800), width: 1.5),
            ),
          ),
        ),
        Positioned(
          top: 12,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              'COMBO ${comboCount}X',
              style: GoogleFonts.chakraPetch(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Color(0xFF4A2800),
                    offset: Offset(1.5, 2.0),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShakeController {
  AnimationController? _controller;

  void setController(AnimationController controller) {
    _controller = controller;
  }

  void shake() {
    _controller?.forward(from: 0.0);
  }

  void dispose() {
    _controller?.dispose();
  }
}

class ShakeWidget extends StatefulWidget {
  final ShakeController controller;
  final Widget child;

  const ShakeWidget({super.key, required this.controller, required this.child});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    widget.controller.setController(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shake = math.sin(_animation.value * math.pi * 4) * 8.0 * (1 - _animation.value);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

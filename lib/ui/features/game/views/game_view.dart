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
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/green_game_button.dart';
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

  int? _activeDragIndex;
  Offset? _dragPosition;
  Offset? _pointerDownPosition;

  static const double _kLiftOffsetY = 75.0;

  final ShakeController _shakeController = ShakeController();
  final GlobalKey _gridKey = GlobalKey();
  final List<GlobalKey> _slotKeys = List.generate(3, (_) => GlobalKey());

  void _onPointerDown(PointerDownEvent details) {
    final gameState = ref.read(gameViewModelProvider);
    int? touchedSlotIndex;

    for (int i = 0; i < 3; i++) {
      if (i >= gameState.availablePieces.length || gameState.availablePieces[i] == null) continue;
      final box = _slotKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final localPos = box.globalToLocal(details.position);
        if (box.paintBounds.contains(localPos)) {
          touchedSlotIndex = i;
          break;
        }
      }
    }

    if (touchedSlotIndex != null) {
      AudioService.instance.playClickSound();
      setState(() {
        _activeDragIndex = touchedSlotIndex;
        _dragPosition = details.position;
        _pointerDownPosition = details.position;
        _selectedPieceIndex = touchedSlotIndex;
        _hoveredPieceIndex = touchedSlotIndex;
      });
      final piece = gameState.availablePieces[touchedSlotIndex];
      if (piece != null) {
        _updateHoverFromTouch(details.position, piece, _kLiftOffsetY);
      }
    }
  }

  void _onPointerMove(PointerMoveEvent details) {
    if (_activeDragIndex == null) return;
    final gameState = ref.read(gameViewModelProvider);
    if (_activeDragIndex! >= gameState.availablePieces.length) return;
    final piece = gameState.availablePieces[_activeDragIndex!];
    if (piece == null) return;

    setState(() {
      _dragPosition = details.position;
    });
    _updateHoverFromTouch(details.position, piece, _kLiftOffsetY);
  }

  void _onPointerUp(PointerUpEvent details) {
    if (_activeDragIndex == null) return;
    final moveDist = _pointerDownPosition != null
        ? (details.position - _pointerDownPosition!).distance
        : 100.0;

    final pIdx = _activeDragIndex!;

    if (moveDist < 12.0) {
      // Tap on card slot without significant dragging -> Toggle tap selection mode!
      setState(() {
        if (_selectedPieceIndex == pIdx && _hoveredStartRow == null) {
          _selectedPieceIndex = null;
          _hoveredPieceIndex = null;
        } else {
          _selectedPieceIndex = pIdx;
          _hoveredPieceIndex = pIdx;
        }
        _activeDragIndex = null;
        _dragPosition = null;
        _pointerDownPosition = null;
      });
    } else {
      // Drag gesture release
      if (_hoveredStartRow != null && _hoveredStartCol != null) {
        final placed = ref.read(gameViewModelProvider.notifier).placePiece(pIdx, _hoveredStartRow!, _hoveredStartCol!);
        if (placed) {
          AudioService.instance.playClearSound();
        }
      }
      setState(() {
        _selectedPieceIndex = null;
        _hoveredPieceIndex = null;
        _hoveredStartRow = null;
        _hoveredStartCol = null;
        _activeDragIndex = null;
        _dragPosition = null;
        _pointerDownPosition = null;
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent details) {
    if (_activeDragIndex != null) {
      setState(() {
        _activeDragIndex = null;
        _dragPosition = null;
        _pointerDownPosition = null;
        _hoveredStartRow = null;
        _hoveredStartCol = null;
      });
    }
  }

  void _updateHoverFromTouch(Offset globalPosition, BlockShape piece, double touchOffsetY) {
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final level = ref.read(gameViewModelProvider).level;
    if (level == null) return;

    final gridLocal = renderBox.globalToLocal(globalPosition);

    final gridContentX = gridLocal.dx - 2.5;
    final gridContentY = (gridLocal.dy - touchOffsetY) - 2.5;

    final gridWidth = renderBox.size.width - 5.0;
    final gridSize = level.gridSize;

    // Grid spacing between cells is 3.0
    final cellWidth = (gridWidth - (gridSize - 1) * 3.0) / gridSize;
    final cellStride = cellWidth + 3.0;

    final pieceWidth = piece.cols * cellStride;
    final pieceHeight = piece.rows * cellStride;

    final pieceTopLeftX = gridContentX - (pieceWidth / 2.0);
    final pieceTopLeftY = gridContentY - (pieceHeight / 2.0);

    final double floatC = pieceTopLeftX / cellStride;
    final double floatR = pieceTopLeftY / cellStride;

    final gameState = ref.read(gameViewModelProvider);

    int baseR = floatR.round();
    int baseC = floatC.round();

    int? bestR;
    int? bestC;
    double minDistanceSq = double.infinity;
  
    for (int dr = -2; dr <= 2; dr++) {
      for (int dc = -2; dc <= 2; dc++) {
        final candR = baseR + dr;
        final candC = baseC + dc;

        final isInBounds = candR >= 0 &&
            (candR + piece.rows) <= gridSize &&
            candC >= 0 &&
            (candC + piece.cols) <= gridSize;

        if (isInBounds) {
          final canPlace = BlockBlastRules.canPlacePiece(gameState.board, piece, candR, candC);
          if (canPlace) {
            final double distR = floatR - candR;
            final double distC = floatC - candC;
            final double distSq = distR * distR + distC * distC;

            if (distSq < minDistanceSq) {
              minDistanceSq = distSq;
              bestR = candR;
              bestC = candC;
            }
          }
        }
      }
    }

    // Magnet snap threshold radius (within ~1.5 cells)
    if (bestR != null && bestC != null && minDistanceSq <= 2.25) {
      if (_hoveredStartRow != bestR || _hoveredStartCol != bestC) {
        HapticFeedback.selectionClick();
        setState(() {
          _hoveredStartRow = bestR;
          _hoveredStartCol = bestC;
        });
      }
      return;
    }

    if (_hoveredStartRow != null || _hoveredStartCol != null) {
      setState(() {
        _hoveredStartRow = null;
        _hoveredStartCol = null;
      });
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

    return PopScope(
      canPop: !widget.isDaily || !state.hasMadeMove || state.isGameOver || state.isComplete,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.isDaily && state.hasMadeMove && !state.isGameOver && !state.isComplete) {
          final shouldQuit = await _showQuitDailyConfirmDialog(context);
          if (shouldQuit == true && context.mounted) {
            await ref.read(gameViewModelProvider.notifier).quitDailyGameIfMoved();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gameBg, // Card / Scaffold Background #090027
        body: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: ShakeWidget(
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
                    child: _buildBottomFlowerBadge(state),
                  ),

                  // Floating Score, Combo & Curved "LINE CLEAR!" Overlay
                  FloatingScoreOverlay(
                    lastScore: state.lastMoveScore,
                    combo: state.comboCount,
                    clearedLines: state.lastClearedLines,
                  ),

                  ConfettiExplosion(trigger: state.isComplete),

                  if (_activeDragIndex != null && _dragPosition != null)
                    _buildFloatingDraggedPiece(state),

                  if (state.isGameOver)
                    Positioned.fill(
                      child: widget.isDaily
                          ? DailyGardenGameOverView(
                              onDailyGarden: () {
                                Navigator.of(context).pop();
                              },
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

                  if (state.isComplete)
                    Positioned.fill(
                      child: LevelCompletedOverlay(
                        levelNumber: widget.levelNumber,
                        onNextLevel: () {
                          if (widget.isRandom) {
                            ref
                                .read(gameViewModelProvider.notifier)
                                .loadRandomLevel(state.randomDifficulty ?? 'Easy');
                          } else {
                            Navigator.of(context).pop('next_level');
                          }
                        },
                        onBackToHome: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showQuitDailyConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF001834),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFC800), width: 1.5),
        ),
        title: Text(
          'QUIT DAILY CHALLENGE?',
          style: GoogleFonts.chakraPetch(
            color: const Color(0xFFFFC800),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'You have made moves in today\'s challenge. Quitting now will save your attempt for today with your current score.',
          style: GoogleFonts.chakraPetch(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'KEEP PLAYING',
              style: GoogleFonts.chakraPetch(color: const Color(0xFF6EE7B7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'QUIT & SAVE',
              style: GoogleFonts.chakraPetch(color: const Color(0xFFFF4081)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDraggedPiece(GameViewModelState state) {
    if (_activeDragIndex == null || _dragPosition == null) return const SizedBox.shrink();
    final pIdx = _activeDragIndex!;
    if (pIdx >= state.availablePieces.length) return const SizedBox.shrink();
    final piece = state.availablePieces[pIdx];
    if (piece == null) return const SizedBox.shrink();

    final colorIdx = pIdx < state.pieceColors.length ? state.pieceColors[pIdx] + 1 : 1;
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    final level = state.level;
    if (renderBox == null || level == null) return const SizedBox.shrink();

    final gridWidth = renderBox.size.width - 5.0;
    final gridCellSize = (gridWidth - (level.gridSize - 1) * 3.0) / level.gridSize;
    final cellStride = gridCellSize + 3.0;

    final pieceWidth = piece.cols * cellStride;
    final pieceHeight = piece.rows * cellStride;

    final left = _dragPosition!.dx - (pieceWidth / 2.0);
    final top = _dragPosition!.dy - _kLiftOffsetY - (pieceHeight / 2.0);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.04,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.blockColors[(colorIdx - 1) % AppColors.blockColors.length].withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: _buildPiecePreview(piece, colorIdx, scale: gridCellSize),
            ),
          ),
        ),
      ),
    );
  }

  // --- TOP BAR HEADER ---
  Widget _buildTopBar(BuildContext context, GameViewModelState state) {
    final displayTarget = state.level?.targetScore ?? 25000;

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

  // Bottom Right Flower Badge using flower_view_design.png & leaf.png (only flower record)
  Widget _buildBottomFlowerBadge(GameViewModelState state) {
    final flowerCount = state.sessionFlowersEarned;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/flower_view_design.png',
          width: 96,
          height: 48,
          fit: BoxFit.fill,
        ),
        Positioned(
          left: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              _formatScore(flowerCount),
              style: GoogleFonts.chakraPetch(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFE699),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Image.asset(
              'assets/game_flower.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) => Image.asset(
                'assets/flower.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (c2, e2, s2) => const Text('🌸', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
        Positioned(
          right: -10,
          bottom: -6,
          child: Image.asset(
            'assets/leaf.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Image.asset(
              'assets/garden_leaf.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (c2, e2, s2) => const SizedBox.shrink(),
            ),
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

  Widget _buildLosingWarningBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF3B0815),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFF3B30).withValues(alpha: value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.45 * value),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 18),
              const SizedBox(width: 6),
              Text(
                'WARNING: YOU ARE LOSING THE GAME!',
                style: GoogleFonts.chakraPetch(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF8080),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
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

    int totalAvailablePieces = 0;
    int playablePiecesCount = 0;
    for (int i = 0; i < state.availablePieces.length; i++) {
      if (state.availablePieces[i] != null) {
        totalAvailablePieces++;
        if (i < state.isPiecePlayable.length && state.isPiecePlayable[i]) {
          playablePiecesCount++;
        }
      }
    }

    final bool isLosingWarning = !state.isGameOver &&
        totalAvailablePieces > 0 &&
        playablePiecesCount == 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            if (isLosingWarning) _buildLosingWarningBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        final pIdx = details.data;
                        setState(() {
                          _hoveredPieceIndex = pIdx;
                        });
                        if (pIdx < state.availablePieces.length) {
                          final piece = state.availablePieces[pIdx];
                          if (piece != null) {
                            _updateHoverFromTouch(details.offset, piece, _kLiftOffsetY);
                          }
                        }
                        return true;
                      },
                      onLeave: (_) {
                        setState(() {
                          _hoveredStartRow = null;
                          _hoveredStartCol = null;
                        });
                      },
                      onAcceptWithDetails: (details) {
                        final pIdx = details.data;
                        if (_hoveredStartRow != null && _hoveredStartCol != null) {
                          ref
                              .read(gameViewModelProvider.notifier)
                              .placePiece(pIdx, _hoveredStartRow!, _hoveredStartCol!);
                        }
                        setState(() {
                          _selectedPieceIndex = null;
                          _hoveredPieceIndex = null;
                          _hoveredStartRow = null;
                          _hoveredStartCol = null;
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Outer Texture Border Layer (Asset Rectangle 11.png with #003675 color filter)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                image: const DecorationImage(
                                  image: AssetImage('assets/Rectangle 11.png'),
                                  fit: BoxFit.fill,
                                  colorFilter: ColorFilter.mode(
                                    Color(0xFF003675),
                                    BlendMode.srcATop,
                                  ),
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
                              padding: const EdgeInsets.all(7.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Container(
                                  // Inner Simple Solid Blue Container (#003675)
                                  key: _gridKey,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF003675),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  padding: const EdgeInsets.all(2.5),
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
                                              if (_selectedPieceIndex != null && _selectedPieceIndex! < state.availablePieces.length) {
                                                final piece = state.availablePieces[_selectedPieceIndex!];
                                                if (piece != null) {
                                                  int targetR = r - (piece.rows - 1) ~/ 2;
                                                  int targetC = c - (piece.cols - 1) ~/ 2;
                                                  int? bestR;
                                                  int? bestC;
                                                  double minDistanceSq = double.infinity;

                                                  for (int dr = -1; dr <= 1; dr++) {
                                                    for (int dc = -1; dc <= 1; dc++) {
                                                      final candR = targetR + dr;
                                                      final candC = targetC + dc;
                                                      final isInBounds = candR >= 0 &&
                                                          (candR + piece.rows) <= level.gridSize &&
                                                          candC >= 0 &&
                                                          (candC + piece.cols) <= level.gridSize;

                                                      if (isInBounds && BlockBlastRules.canPlacePiece(state.board, piece, candR, candC)) {
                                                        final distSq = (dr * dr + dc * dc).toDouble();
                                                        if (distSq < minDistanceSq) {
                                                          minDistanceSq = distSq;
                                                          bestR = candR;
                                                          bestC = candC;
                                                        }
                                                      }
                                                    }
                                                  }

                                                  if (bestR != null && bestC != null) {
                                                    setState(() {
                                                      _hoveredStartRow = bestR;
                                                      _hoveredStartCol = bestC;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _hoveredStartRow = null;
                                                      _hoveredStartCol = null;
                                                    });
                                                  }
                                                }
                                              }
                                            },
                                            onExit: (_) {},
                                            child: InkWell(
                                              onTap: () {
                                                final notifier = ref.read(gameViewModelProvider.notifier);
                                                if (_selectedPieceIndex != null && _selectedPieceIndex! < state.availablePieces.length) {
                                                  final piece = state.availablePieces[_selectedPieceIndex!];
                                                  if (piece != null) {
                                                    int targetR = r - (piece.rows - 1) ~/ 2;
                                                    int targetC = c - (piece.cols - 1) ~/ 2;
                                                    int? bestR;
                                                    int? bestC;
                                                    double minDistanceSq = double.infinity;

                                                    for (int dr = -1; dr <= 1; dr++) {
                                                      for (int dc = -1; dc <= 1; dc++) {
                                                        final candR = targetR + dr;
                                                        final candC = targetC + dc;
                                                        final isInBounds = candR >= 0 &&
                                                            (candR + piece.rows) <= level.gridSize &&
                                                            candC >= 0 &&
                                                            (candC + piece.cols) <= level.gridSize;

                                                        if (isInBounds && BlockBlastRules.canPlacePiece(state.board, piece, candR, candC)) {
                                                          final distSq = (dr * dr + dc * dc).toDouble();
                                                          if (distSq < minDistanceSq) {
                                                            minDistanceSq = distSq;
                                                            bestR = candR;
                                                            bestC = candC;
                                                          }
                                                        }
                                                      }
                                                    }

                                                    if (bestR != null && bestC != null) {
                                                      final placed = notifier.placePiece(_selectedPieceIndex!, bestR, bestC);
                                                      if (placed) {
                                                        setState(() {
                                                          _selectedPieceIndex = null;
                                                          _hoveredPieceIndex = null;
                                                          _hoveredStartRow = null;
                                                          _hoveredStartCol = null;
                                                        });
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              child: cellWidget,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                            // Combo Card Banner at bottom edge of board grid (pops up & wipes out after a few seconds)
                            Positioned(
                              bottom: -18,
                              child: PersistentComboBanner(comboCount: state.comboCount),
                            ),
                          ],
                        );
                      },
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
                  final isPlayable = pIdx < state.isPiecePlayable.length ? state.isPiecePlayable[pIdx] : true;

                  return Expanded(
                    child: Container(
                      key: _slotKeys[pIdx],
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('piece_arrival_${state.trayGenerationId}_$pIdx'),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 380 + pIdx * 90),
                        curve: Curves.easeOutBack,
                        builder: (context, animVal, child) {
                          final scale = (0.2 + 0.8 * animVal).clamp(0.0, 1.05);
                          final offsetY = (1.0 - animVal) * 32.0;

                          return Transform.translate(
                            offset: Offset(0, offsetY),
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.all(4),
                          transform: Matrix4.diagonal3Values(
                            isSelected ? 1.05 : 1.0,
                            isSelected ? 1.05 : 1.0,
                            1.0,
                          ),
                          transformAlignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF002855)
                                : !isPlayable
                                    ? const Color(0xFF160A18)
                                    : const Color(0xFF001834),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFC800)
                                  : !isPlayable
                                      ? const Color(0xFF6B1D2F)
                                      : const Color(0xFF103975),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFC800).withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: LayoutBuilder(
                            builder: (context, pieceBox) {
                              final maxScaleW = (pieceBox.maxWidth - 16) / piece.cols - 2.0;
                              final maxScaleH = (pieceBox.maxHeight - 16) / piece.rows - 2.0;
                              final blockSize = math.max(8.0, math.min(22.0, math.min(maxScaleW, maxScaleH)));
                              final isBeingDragged = _activeDragIndex == pIdx;

                              return Stack(
                                children: [
                                  Center(
                                    child: Opacity(
                                      opacity: isBeingDragged ? 0.15 : (!isPlayable ? 0.38 : 1.0),
                                      child: _buildPiecePreview(piece, colorIdx, scale: blockSize),
                                    ),
                                  ),
                                  if (!isPlayable && !isBeingDragged)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF881B1B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.block_rounded,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
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
      if (isValidPlacement) {
        return TweenAnimationBuilder<double>(
          key: ValueKey('preview_$r-$c'),
          tween: Tween<double>(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          builder: (context, scaleVal, child) {
            return Transform.scale(
              scale: scaleVal,
              child: Opacity(
                opacity: 0.92,
                child: _buildBlockAsset(activeColorIndex, isPreview: true),
              ),
            );
          },
        );
      }
      return const SizedBox.shrink();
    } else {
      // Empty cell
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isBombHovered
              ? Colors.redAccent.withValues(alpha: 0.3)
              : isLineGlowing
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF000B1E),
          borderRadius: BorderRadius.circular(4),
          border: isBombHovered
              ? Border.all(color: Colors.redAccent, width: 1.5)
              : isLineGlowing
                  ? Border.all(color: const Color(0xFF007AFF), width: 1.2)
                  : Border.all(color: const Color(0xFF003675), width: 0.8),
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
        border: Border.all(color: const Color(0xFF003675), width: 0.8),
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
  }

  Future<void> _onGameOver(GameViewModelState state) async {
    if (!mounted) return;
    AudioService.instance.playGameOverSound();
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

    if (widget.lastScore > 0 || widget.clearedLines > 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingScoreOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.lastScore > 0 && widget.lastScore != oldWidget.lastScore) ||
        (widget.clearedLines > 0 && widget.clearedLines != oldWidget.clearedLines)) {
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
    if (widget.lastScore <= 0 && widget.clearedLines <= 0) {
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
            // Center Curved LINE CLEAR! Overlay Banner
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

/// Combo Card Banner at bottom edge of game grid (pops up & wipes out after ~2 seconds)
class PersistentComboBanner extends StatefulWidget {
  final int comboCount;

  const PersistentComboBanner({
    super.key,
    required this.comboCount,
  });

  @override
  State<PersistentComboBanner> createState() => _PersistentComboBannerState();
}

class _PersistentComboBannerState extends State<PersistentComboBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _offsetY;
  int _activeCombo = 0;

  @override
  void initState() {
    super.initState();
    _activeCombo = widget.comboCount;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.08).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 47,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 25,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    _offsetY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 22.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 57,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 15.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
    ]).animate(_controller);

    if (widget.comboCount > 1) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(PersistentComboBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comboCount > 1 && widget.comboCount != oldWidget.comboCount) {
      setState(() {
        _activeCombo = widget.comboCount;
      });
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
    if (_activeCombo <= 1) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating && _controller.isCompleted) {
          return const SizedBox.shrink();
        }

        return Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/combo_board.png',
            width: 175,
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
            top: 11,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'COMBO ${_activeCombo}X',
                style: GoogleFonts.chakraPetch(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
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
      ),
    );
  }
}

/// Level Completed Victory Overlay
class LevelCompletedOverlay extends ConsumerWidget {
  const LevelCompletedOverlay({
    super.key,
    required this.levelNumber,
    required this.onNextLevel,
    required this.onBackToHome,
  });

  final int levelNumber;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToHome;

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    final score = state.score;
    final flowers = state.sessionFlowersEarned;
    final bloomCount = state.totalClears;
    final maxCombo = state.maxComboCount > 0
        ? state.maxComboCount
        : (state.comboCount > 0 ? state.comboCount : 1);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xEE07031A),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 2-Line Curved Arched Level Complete Header Title matching other pages
                  const FloralHeaderTitle(
                    topTitle: 'LEVEL',
                    title: 'COMPLETE',
                    fontSize: 45.0,
                    topFontSize: 45.0,
                    flowerSize: 46.0,
                    curveAmount: 18.0,
                    topCurveAmount: 14.0,
                    topTitleSpacing: -5.0,
                    letterSpacing: 1.5,
                  ),

                  const SizedBox(height: 24),

                  // Score & Stats Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF071E36), Color(0xFF041223)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFC800),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC800).withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // YOUR SCORE text matching Figma spec image
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Text(
                            'YOUR SCORE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.chakraPetch(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              letterSpacing: 0.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          _formatScore(score),
                          style: GoogleFonts.chakraPetch(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFF066),
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(
                                color: Color(0xAA814D00),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(
                          color: Color(0xFF1E3A5F),
                          height: 1,
                          thickness: 1.0,
                        ),
                        const SizedBox(height: 16),

                        // 3-Column Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Column 1: FLOWERS
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/game_flower.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Text(
                                      '🌸',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'FLOWERS',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                          letterSpacing: 0.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+$flowers',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFF066),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider 1
                            Container(
                              height: 46,
                              width: 1,
                              color: const Color(0xFF1E3A5F),
                            ),

                            // Column 2: BLOOM
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/game_leaf.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Text(
                                      '🌱',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'BLOOM',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                          letterSpacing: 0.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$bloomCount',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFF066),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider 2
                            Container(
                              height: 46,
                              width: 1,
                              color: const Color(0xFF1E3A5F),
                            ),

                            // Column 3: MAX COMBO
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/stats/star.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Text(
                                      '⭐',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'MAX COMBO',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                          letterSpacing: 0.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'X$maxCombo',
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFF066),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // NEXT LEVEL Glossy Green Button matching reference radius (14.0)
                  GreenGameButton(
                    text: 'NEXT LEVEL',
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    width: 220.0,
                    height: 50.0,
                    borderRadius: 14.0,
                    fontSize: 16,
                    onPressed: () {
                      AudioService.instance.playClickSound();
                      onNextLevel();
                    },
                  ),

                  const SizedBox(height: 14),

                  // BACK TO HOME Text Link Button
                  GestureDetector(
                    onTap: () {
                      AudioService.instance.playClickSound();
                      onBackToHome();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        'BACK TO HOME',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2096E7),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF2096E7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom arched Level Complete header title where both LEVEL and COMPLETE are prominent,
/// properly vertically spaced, and flanked by flower icons matching the reference image.
class LevelCompleteHeaderTitle extends StatelessWidget {
  const LevelCompleteHeaderTitle({super.key});

  Widget _buildArchedWord(String text, {required double fontSize, double curveAmount = 8.0}) {
    final characters = text.split('');
    final totalChars = characters.length;
    const double refHalfSpan = 4.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalChars, (i) {
        final centerIndex = (totalChars - 1) / 2.0;
        final xFromCenter = i - centerIndex;
        final t = totalChars > 1 ? (xFromCenter / refHalfSpan) : 0.0;
        final dy = (1.0 - (t * t)) * -curveAmount;
        final angle = t * 0.12;

        if (characters[i] == ' ') {
          return SizedBox(width: fontSize * 0.35);
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFF7A1), Color(0xFFFFD700), Color(0xFFFF9E00)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  characters[i],
                  style: GoogleFonts.chakraPetch(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF6B3E00),
                        offset: Offset(1.5, 2.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top line: Arched LEVEL (large, bold gold font, clearly positioned above)
        _buildArchedWord('LEVEL', fontSize: 32.0, curveAmount: 10.0),

        const SizedBox(height: 8),

        // Bottom line: 🌸 Arched COMPLETE 🌸
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Flower
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Transform.rotate(
                angle: -0.15,
                child: Image.asset(
                  'assets/flower.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('🌸', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Arched COMPLETE
            _buildArchedWord('COMPLETE', fontSize: 36.0, curveAmount: 12.0),

            const SizedBox(width: 8),

            // Right Flower
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Transform.scale(
                scaleX: -1,
                child: Transform.rotate(
                  angle: -0.15,
                  child: Image.asset(
                    'assets/flower.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('🌸', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


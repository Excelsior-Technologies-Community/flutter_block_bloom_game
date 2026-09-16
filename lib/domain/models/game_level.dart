import 'package:flutter/foundation.dart';

class BlockShape {
  final List<List<int>> matrix;
  final int rows;
  final int cols;

  BlockShape({required this.matrix})
      : rows = matrix.length,
        cols = matrix.isEmpty ? 0 : matrix[0].length;

  bool get isBomb => matrix.length == 1 && matrix[0].length == 1 && matrix[0][0] == 2;

  static final BlockShape bomb = BlockShape(matrix: [
    [2]
  ]);

  // 1. Seed (1x1)
  static final BlockShape single = BlockShape(matrix: [
    [1]
  ]);

  // 2. Small Line (1x2 H & V)
  static final BlockShape line2H = BlockShape(matrix: [
    [1, 1]
  ]);
  static final BlockShape line2V = BlockShape(matrix: [
    [1],
    [1]
  ]);

  // 3. Triple Line (1x3 H & V)
  static final BlockShape line3H = BlockShape(matrix: [
    [1, 1, 1]
  ]);
  static final BlockShape line3V = BlockShape(matrix: [
    [1],
    [1],
    [1]
  ]);

  // 4. Long Line (1x4 H & V)
  static final BlockShape line4H = BlockShape(matrix: [
    [1, 1, 1, 1]
  ]);
  static final BlockShape line4V = BlockShape(matrix: [
    [1],
    [1],
    [1],
    [1]
  ]);

  // 5. Small L (2x2 L shapes - 3 blocks)
  static final BlockShape l2x2TL = BlockShape(matrix: [
    [1, 1],
    [1, 0]
  ]);
  static final BlockShape l2x2TR = BlockShape(matrix: [
    [1, 1],
    [0, 1]
  ]);
  static final BlockShape l2x2BL = BlockShape(matrix: [
    [1, 0],
    [1, 1]
  ]);
  static final BlockShape l2x2BR = BlockShape(matrix: [
    [0, 1],
    [1, 1]
  ]);

  // 6. L Block (3x2 L shapes - 4 blocks)
  static final BlockShape l3x2V = BlockShape(matrix: [
    [1, 0],
    [1, 0],
    [1, 1]
  ]);
  static final BlockShape l3x2VRot = BlockShape(matrix: [
    [1, 1, 1],
    [1, 0, 0]
  ]);

  // 7. Reverse L (3x2 Reverse L shapes - 4 blocks)
  static final BlockShape l3x2VRev = BlockShape(matrix: [
    [0, 1],
    [0, 1],
    [1, 1]
  ]);
  static final BlockShape l3x2VRevRot = BlockShape(matrix: [
    [1, 1, 1],
    [0, 0, 1]
  ]);

  // 8. Square (2x2)
  static final BlockShape square2x2 = BlockShape(matrix: [
    [1, 1],
    [1, 1]
  ]);
  static final BlockShape square3x3 = BlockShape(matrix: [
    [1, 1, 1],
    [1, 1, 1],
    [1, 1, 1]
  ]);

  // 9. T Block (T-shapes)
  static final BlockShape tDown = BlockShape(matrix: [
    [1, 1, 1],
    [0, 1, 0]
  ]);
  static final BlockShape tUp = BlockShape(matrix: [
    [0, 1, 0],
    [1, 1, 1]
  ]);
  static final BlockShape tLeft = BlockShape(matrix: [
    [0, 1],
    [1, 1],
    [0, 1]
  ]);
  static final BlockShape tRight = BlockShape(matrix: [
    [1, 0],
    [1, 1],
    [1, 0]
  ]);

  // 10. Z Block (Z-shapes)
  static final BlockShape zH = BlockShape(matrix: [
    [1, 1, 0],
    [0, 1, 1]
  ]);
  static final BlockShape zV = BlockShape(matrix: [
    [0, 1],
    [1, 1],
    [1, 0]
  ]);

  // 11. S Block (S-shapes)
  static final BlockShape sH = BlockShape(matrix: [
    [0, 1, 1],
    [1, 1, 0]
  ]);
  static final BlockShape sV = BlockShape(matrix: [
    [1, 0],
    [1, 1],
    [0, 1]
  ]);

  // 12. Plus (3x3 Cross - 5 blocks)
  static final BlockShape plus = BlockShape(matrix: [
    [0, 1, 0],
    [1, 1, 1],
    [0, 1, 0]
  ]);

  // 13. Big L (3x3 Big L shapes - 5 blocks)
  static final BlockShape l3x3TL = BlockShape(matrix: [
    [1, 1, 1],
    [1, 0, 0],
    [1, 0, 0]
  ]);
  static final BlockShape l3x3TR = BlockShape(matrix: [
    [1, 1, 1],
    [0, 0, 1],
    [0, 0, 1]
  ]);
  static final BlockShape l3x3BL = BlockShape(matrix: [
    [1, 0, 0],
    [1, 0, 0],
    [1, 1, 1]
  ]);
  static final BlockShape l3x3BR = BlockShape(matrix: [
    [0, 0, 1],
    [0, 0, 1],
    [1, 1, 1]
  ]);

  // 14. 5 Line (1x5 H & V)
  static final BlockShape line5H = BlockShape(matrix: [
    [1, 1, 1, 1, 1]
  ]);
  static final BlockShape line5V = BlockShape(matrix: [
    [1],
    [1],
    [1],
    [1],
    [1]
  ]);

  static final List<BlockShape> allShapes = [
    // 1. Seed
    single,
    // 2. Small Line
    line2H, line2V,
    // 3. Triple Line
    line3H, line3V,
    // 4. Long Line
    line4H, line4V,
    // 5. Small L
    l2x2TL, l2x2TR, l2x2BL, l2x2BR,
    // 6. L Block
    l3x2V, l3x2VRot,
    // 7. Reverse L
    l3x2VRev, l3x2VRevRot,
    // 8. Square
    square2x2, square3x3,
    // 9. T Block
    tDown, tUp, tLeft, tRight,
    // 10. Z Block
    zH, zV,
    // 11. S Block
    sH, sV,
    // 12. Plus
    plus,
    // 13. Big L
    l3x3TL, l3x3TR, l3x3BL, l3x3BR,
    // 14. 5 Line
    line5H, line5V,
  ];
}

@immutable
class GameLevel {
  const GameLevel({
    required this.levelNumber,
    required this.gridSize,
    required this.targetScore,
    required this.targetClears,
    required this.initialGrid,
  });

  final int levelNumber;
  final int gridSize;
  final int targetScore;
  final int targetClears;
  final List<List<int>> initialGrid;
}

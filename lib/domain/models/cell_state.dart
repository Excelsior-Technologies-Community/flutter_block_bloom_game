import 'package:flutter/foundation.dart';

enum CellType { empty, occupied, bloom, flower }

enum FlowerType { sunflower, blueFlower, redFlower }

@immutable
class BoardCell {
  const BoardCell({
    required this.type,
    this.colorIndex = 0,
    this.flowerType,
  });

  final CellType type;
  final int colorIndex; // 1..8 for block color variants, 0 if empty
  final FlowerType? flowerType;

  static const BoardCell empty = BoardCell(type: CellType.empty, colorIndex: 0);

  bool get isEmpty => type == CellType.empty;
  bool get isOccupied => type == CellType.occupied;
  bool get isBloom => type == CellType.bloom;
  bool get isFlower => type == CellType.flower;

  BoardCell copyWith({
    CellType? type,
    int? colorIndex,
    FlowerType? flowerType,
  }) {
    return BoardCell(
      type: type ?? this.type,
      colorIndex: colorIndex ?? this.colorIndex,
      flowerType: flowerType ?? this.flowerType,
    );
  }
}

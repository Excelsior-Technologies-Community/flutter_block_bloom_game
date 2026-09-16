import 'package:block_bloom/domain/models/cell_state.dart';
import 'package:block_bloom/domain/models/game_level.dart';

class BlockBlastRules {
  static bool canPlacePiece(
    List<List<BoardCell>> board,
    BlockShape piece,
    int startRow,
    int startCol,
  ) {
    final n = board.length;
    if (startRow < 0 || startCol < 0) return false;
    if (startRow + piece.rows > n || startCol + piece.cols > n) return false;

    if (piece.isBomb) return true; // Bomb can be placed on any tile within bounds

    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.matrix[r][c] == 1) {
          if (board[startRow + r][startCol + c].type != CellType.empty) {
            return false;
          }
        }
      }
    }
    return true;
  }

  static int getLineClearPoints(int clearedLines) {
    if (clearedLines <= 0) return 0;
    if (clearedLines == 1) return 200;
    if (clearedLines == 2) return 500;
    if (clearedLines == 3) return 1000;
    return 2000 + (clearedLines - 4) * 1000;
  }

  static double getComboMultiplier(int comboCount) {
    if (comboCount <= 1) return 1.0;
    if (comboCount == 2) return 2.4;
    if (comboCount == 3) return 3.0;
    if (comboCount == 4) return 4.0;
    return 5.0; // Combo x5+
  }

  static bool canPieceBePlacedAnywhere(
    List<List<BoardCell>> board,
    BlockShape? piece,
  ) {
    if (piece == null) return false;
    final n = board.length;
    for (int r = 0; r <= n - piece.rows; r++) {
      for (int c = 0; c <= n - piece.cols; c++) {
        if (canPlacePiece(board, piece, r, c)) {
          return true;
        }
      }
    }
    return false;
  }

  static List<Map<String, int>> getPlayablePositions(
    List<List<BoardCell>> board,
    BlockShape? piece,
  ) {
    if (piece == null) return [];
    final n = board.length;
    final positions = <Map<String, int>>[];
    for (int r = 0; r <= n - piece.rows; r++) {
      for (int c = 0; c <= n - piece.cols; c++) {
        if (canPlacePiece(board, piece, r, c)) {
          positions.add({'row': r, 'col': c});
        }
      }
    }
    return positions;
  }

  static bool canAnyPieceBePlaced(
    List<List<BoardCell>> board,
    List<BlockShape?> pieces,
  ) {
    for (final piece in pieces) {
      if (canPieceBePlacedAnywhere(board, piece)) {
        return true;
      }
    }
    return false;
  }

  static List<int> getCompletedRows(List<List<BoardCell>> board) {
    final n = board.length;
    final rows = <int>[];
    for (int r = 0; r < n; r++) {
      bool full = true;
      for (int c = 0; c < n; c++) {
        if (board[r][c].type == CellType.empty) {
          full = false;
          break;
        }
      }
      if (full) rows.add(r);
    }
    return rows;
  }

  static List<int> getCompletedCols(List<List<BoardCell>> board) {
    final n = board.length;
    final cols = <int>[];
    for (int c = 0; c < n; c++) {
      bool full = true;
      for (int r = 0; r < n; r++) {
        if (board[r][c].type == CellType.empty) {
          full = false;
          break;
        }
      }
      if (full) cols.add(c);
    }
    return cols;
  }
}

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
    if (clearedLines == 1) return 100;
    if (clearedLines == 2) return 250;
    if (clearedLines == 3) return 500;
    return 1000 + (clearedLines - 4) * 500;
  }

  static double getComboMultiplier(int comboCount) {
    if (comboCount <= 1) return 1.0;
    if (comboCount == 2) return 1.2;
    if (comboCount == 3) return 1.5;
    if (comboCount == 4) return 2.0;
    return 2.5; // Combo x5+
  }

  static bool canAnyPieceBePlaced(
    List<List<BoardCell>> board,
    List<BlockShape?> pieces,
  ) {
    final n = board.length;
    for (final piece in pieces) {
      if (piece == null) continue;
      for (int r = 0; r <= n - piece.rows; r++) {
        for (int c = 0; c <= n - piece.cols; c++) {
          if (canPlacePiece(board, piece, r, c)) {
            return true;
          }
        }
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

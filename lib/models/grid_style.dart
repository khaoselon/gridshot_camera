enum GridStyle {
  grid2x2(2, 2),
  grid2x3(2, 3),
  grid3x2(3, 2),
  grid3x3(3, 3);

  const GridStyle(this.columns, this.rows);

  final int columns;
  final int rows;

  int get totalCells => columns * rows;

  String get displayName {
    return '$columns×$rows';
  }

  /// グリッドセルのインデックスから行と列を取得
  GridPosition getPosition(int index) {
    final row = index ~/ columns;
    final col = index % columns;
    return GridPosition(row, col);
  }

  /// 行と列からグリッドセルのインデックスを取得
  int getIndex(int row, int col) {
    return row * columns + col;
  }

  /// すべてのグリッドポジションを取得
  List<GridPosition> getAllPositions() {
    List<GridPosition> positions = [];
    for (int i = 0; i < totalCells; i++) {
      positions.add(getPosition(i));
    }
    return positions;
  }
}

class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'GridPosition($row, $col)';

  /// 表示用の位置文字列を取得（例: "A1", "B2"など）
  String get displayString {
    final rowLetter = String.fromCharCode(65 + row); // A, B, C...
    final colNumber = col + 1; // 1, 2, 3...
    return '$rowLetter$colNumber';
  }
}

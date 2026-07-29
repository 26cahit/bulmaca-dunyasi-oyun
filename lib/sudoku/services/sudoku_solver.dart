class SudokuSolver {
  static bool solve(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1);
          numbers.shuffle();

          for (final number in numbers) {
            if (_isValid(board, row, col, number)) {
              board[row][col] = number;

              if (solve(board)) {
                return true;
              }

              board[row][col] = 0;
            }
          }

          return false;
        }
      }
    }

    return true;
  }

  static bool _isValid(List<List<int>> board, int row, int col, int number) {
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == number) return false;
      if (board[i][col] == number) return false;
    }

    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;

    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (board[r][c] == number) {
          return false;
        }
      }
    }

    return true;
  }

  static bool isSolved(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        int value = board[row][col];

        if (value == 0) {
          return false;
        }

        board[row][col] = 0;

        bool valid = _isValid(board, row, col, value);

        board[row][col] = value;

        if (!valid) {
          return false;
        }
      }
    }

    return true;
  }
}


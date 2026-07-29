import 'sudoku_cell.dart';

class SudokuBoard {
  List<List<bool>> completedBoxes = List.generate(
    3,
    (_) => List.generate(3, (_) => false),
  );
  List<List<SudokuCell>> cells;

  SudokuBoard({required this.cells});

  SudokuCell getCell(int row, int col) {
    return cells[row][col];
  }

  void setValue(int row, int col, int value) {
    if (cells[row][col].fixed) return;

    cells[row][col].value = value;
    cells[row][col].error = value != 0 && value != cells[row][col].solution;
    checkCompletedBoxes();
  }

  void clearValue(int row, int col) {
    if (cells[row][col].fixed) return;

    cells[row][col].value = 0;
    cells[row][col].error = false;
  }

  void clearSelection() {
    for (final row in cells) {
      for (final cell in row) {
        cell.selected = false;
      }
    }
  }

  void selectCell(int row, int col) {
    clearSelection();
    cells[row][col].selected = true;
  }

  bool isCompleted() {
    for (final row in cells) {
      for (final cell in row) {
        if (cell.value != cell.solution) {
          return false;
        }
      }
    }
    return true;
  }
void checkCompletedBoxes() {
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        bool completed = true;

        for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
          for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
            if (cells[r][c].value != cells[r][c].solution) {
              completed = false;
              break;
            }
          }
        }

        completedBoxes[boxRow][boxCol] = completed;
      }
    }
  }
  void clearAllUserCells() {
    for (final row in cells) {
      for (final cell in row) {
        if (!cell.fixed) {
          cell.value = 0;
          cell.error = false;
          cell.clearNotes();
        }
      }
    }
  }

  SudokuBoard copy() {
    return SudokuBoard(
      cells: cells
          .map((row) => row.map((cell) => cell.copyWith()).toList())
          .toList(),
    );
  }
}

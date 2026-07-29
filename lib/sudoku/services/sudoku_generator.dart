import 'dart:math';

import '../models/sudoku_board.dart';
import '../models/sudoku_cell.dart';
import 'sudoku_solver.dart';

class SudokuGenerator {
  static final Random _random = Random();

  static SudokuBoard generate({String difficulty = "easy"}) {
    List<List<int>> solvedBoard = List.generate(9, (_) => List.filled(9, 0));

    SudokuSolver.solve(solvedBoard);

    List<List<int>> puzzle = solvedBoard
        .map((row) => List<int>.from(row))
        .toList();

    int removeCount;

    switch (difficulty) {
      case "easy":
        removeCount = 35;
        break;

      case "medium":
        removeCount = 45;
        break;

      case "hard":
        removeCount = 55;
        break;

      case "expert":
        removeCount = 60;
        break;

      default:
        removeCount = 35;
    }

    int removed = 0;

    while (removed < removeCount) {
      int row = _random.nextInt(9);
      int col = _random.nextInt(9);

      if (puzzle[row][col] != 0) {
        puzzle[row][col] = 0;
        removed++;
      }
    }

    List<List<SudokuCell>> cells = List.generate(
      9,
      (row) => List.generate(9, (col) {
        return SudokuCell(
          value: puzzle[row][col],
          solution: solvedBoard[row][col],
          fixed: puzzle[row][col] != 0,
        );
      }),
    );

    return SudokuBoard(cells: cells);
  }
}

class SudokuCell {
  int value;
  int solution;
  bool fixed;
  bool selected;
  bool error;
  Set<int> notes;

  SudokuCell({
    required this.value,
    required this.solution,
    required this.fixed,
    this.selected = false,
    this.error = false,
    Set<int>? notes,
  }) : notes = notes ?? {};

  SudokuCell copyWith({
    int? value,
    int? solution,
    bool? fixed,
    bool? selected,
    bool? error,
    Set<int>? notes,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      solution: solution ?? this.solution,
      fixed: fixed ?? this.fixed,
      selected: selected ?? this.selected,
      error: error ?? this.error,
      notes: notes ?? Set<int>.from(this.notes),
    );
  }

  void clearNotes() {
    notes.clear();
  }

  void toggleNote(int number) {
    if (notes.contains(number)) {
      notes.remove(number);
    } else {
      notes.add(number);
    }
  }

  bool get isEmpty => value == 0;

  bool get isCorrect => value == solution;

  bool get hasNotes => notes.isNotEmpty;
}

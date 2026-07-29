import 'package:flutter/material.dart';
import '../models/sudoku_board.dart';
import '../services/sudoku_generator.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import 'package:confetti/confetti.dart';

class SudokuGameScreen extends StatefulWidget {
  final String difficulty;

  const SudokuGameScreen({super.key, required this.difficulty});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen>
    with SingleTickerProviderStateMixin {
  late SudokuBoard board;

  int selectedRow = -1;
  int selectedCol = -1;

  late AnimationController glowController;
  late Animation<double> glowAnimation;
  late ConfettiController leftConfetti;
  late ConfettiController rightConfetti;

  @override
  void initState() {
    super.initState();

    board = SudokuGenerator.generate(difficulty: widget.difficulty);

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    glowAnimation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));

    glowController.repeat(reverse: true);
    leftConfetti = ConfettiController(duration: const Duration(seconds: 3));

    rightConfetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    glowController.dispose();
    leftConfetti.dispose();
    rightConfetti.dispose();
    super.dispose();
  }

  void selectCell(int row, int col) {
    if (board.cells[row][col].fixed) return;

    setState(() {
      selectedRow = row;
      selectedCol = col;
      board.selectCell(row, col);
    });
  }

  Future<void> enterNumber(int number) async {
    if (selectedRow == -1 || selectedCol == -1) return;

    setState(() {
      board.setValue(selectedRow, selectedCol, number);
    });

    if (board.isCompleted()) {
      int xp = 25;
      int coin = 10;

      switch (widget.difficulty.toLowerCase()) {
        case "orta":
          xp = 50;
          coin = 20;
          break;

        case "zor":
          xp = 100;
          coin = 40;
          break;

        case "uzman":
          xp = 200;
          coin = 80;
          break;
      }

      await context.read<PlayerProvider>().addReward(addXp: xp, addCoins: coin);
      leftConfetti.play();
      rightConfetti.play();
      if (!mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "",
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xff1B1F2A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.amber.withOpacity(.45),
                      blurRadius: 35,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 80,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "TEBRİKLER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Sudoku Tamamlandı",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "⭐ XP +$xp",
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "🪙 Coin +$coin",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text(
                          "DEVAM ET",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (_, animation, _, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
    }
  }

  void clearCell() {
    if (selectedRow == -1 || selectedCol == -1) return;

    setState(() {
      board.clearValue(selectedRow, selectedCol);
    });
  }

  void clearAllCells() {
    setState(() {
      board.clearAllUserCells();

      selectedRow = -1;
      selectedCol = -1;

      board.clearSelection();
    });
  }

  Color borderColor(int row, int col) {
    int boxRow = row ~/ 3;
    int boxCol = col ~/ 3;

    if (board.completedBoxes[boxRow][boxCol]) {
      return Colors.greenAccent;
    }

    if (board.cells[row][col].selected) {
      return Colors.amber;
    }

    return Colors.black;
  }

  double borderWidth(int row, int col) {
    int boxRow = row ~/ 3;
    int boxCol = col ~/ 3;

    if (board.completedBoxes[boxRow][boxCol]) {
      return 2.5;
    }

    if (board.cells[row][col].selected) {
      return 3;
    }

    return 0.5;
  }

  Widget buildGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: List.generate(9, (row) {
          return Expanded(
            child: Row(
              children: List.generate(9, (col) {
                final cell = board.cells[row][col];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      selectCell(row, col);
                    },
                    child: AnimatedBuilder(
                      animation: glowAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: board.completedBoxes[row ~/ 3][col ~/ 3]
                                // ignore: deprecated_member_use
                                ? Colors.green.withOpacity(.12)
                                : cell.selected
                                // ignore: deprecated_member_use
                                ? Colors.amber.withOpacity(.18)
                                : cell.fixed
                                ? Colors.grey.shade300
                                : Colors.white,

                            border: Border(
                              left: BorderSide(
                                width: col % 3 == 0 ? 2 : borderWidth(row, col),
                                color: borderColor(row, col),
                              ),
                              right: BorderSide(
                                width: col == 8 ? 2 : 0.5,
                                color: borderColor(row, col),
                              ),
                              top: BorderSide(
                                width: row % 3 == 0 ? 2 : borderWidth(row, col),
                                color: borderColor(row, col),
                              ),
                              bottom: BorderSide(
                                width: row == 8 ? 2 : borderWidth(row, col),
                                color: borderColor(row, col),
                              ),
                            ),

                            boxShadow: [
                              if (board.completedBoxes[row ~/ 3][col ~/ 3])
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.greenAccent.withOpacity(.9),
                                  blurRadius: 10 + glowAnimation.value,
                                  spreadRadius: glowAnimation.value / 2,
                                ),
                              if (cell.selected)
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.amber.withOpacity(.9),
                                  blurRadius: 12 + glowAnimation.value,
                                  spreadRadius: glowAnimation.value / 2,
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              cell.value == 0 ? "" : cell.value.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: cell.fixed
                                    ? Colors.black
                                    : cell.error
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget buildNumberPad() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(9, (index) {
        final number = index + 1;

        return SizedBox(
          width: 55,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              enterNumber(number);
            },
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 22),
            ),
          ),
        );
      }),
    );
  }

  Widget buildSelectedInfo() {
    return AnimatedOpacity(
      opacity: selectedRow == -1 ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.amber.withOpacity(.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.touch_app, color: Colors.amber),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Seçili hücreye sayı girebilirsiniz",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101820),
      appBar: AppBar(
        backgroundColor: const Color(0xff101820),
        title: const Text("Sudoku"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  buildGrid(),

                  const SizedBox(height: 20),

                  buildNumberPad(),

                  buildSelectedInfo(),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: clearCell,
                            icon: const Icon(Icons.backspace),
                            label: const Text(
                              "Temizle",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Tümünü Temizle"),
                                  content: const Text(
                                    "Girdiğin bütün sayılar silinecek.\nDevam etmek istiyor musun?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text("İptal"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text("Temizle"),
                                    ),
                                  ],
                                ),
                              );

                              if (result == true) {
                                clearAllCells();
                              }
                            },
                            icon: const Icon(Icons.delete_forever),
                            label: const Text(
                              "Tümünü",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: leftConfetti,
              blastDirection: 0.8,
              emissionFrequency: 0.03,
              numberOfParticles: 20,
              shouldLoop: false,
              gravity: 0.25,
            ),
          ),

          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: rightConfetti,
              blastDirection: 2.3,
              emissionFrequency: 0.03,
              numberOfParticles: 20,
              shouldLoop: false,
              gravity: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

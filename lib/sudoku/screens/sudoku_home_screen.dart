import 'package:flutter/material.dart';

import 'sudoku_game_screen.dart';
import 'dart:math';

class SudokuHomeScreen extends StatelessWidget {
  const SudokuHomeScreen({super.key});

  void _startGame(BuildContext context, String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SudokuGameScreen(difficulty: difficulty),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String title,
    String difficulty,
    Color color,
  ) {
    IconData icon = Icons.star;

    String desc = "";

    String cells = "";

    switch (difficulty) {
      case "easy":
        icon = Icons.eco;
        desc = "Yeni başlayanlar için";
        cells = "36-40";
        break;

      case "medium":
        icon = Icons.auto_awesome;
        desc = "Dengeli zorluk";
        cells = "41-46";
        break;

      case "hard":
        icon = Icons.local_fire_department;
        desc = "Deneyimli oyuncular";
        cells = "47-52";
        break;

      case "expert":
        icon = Icons.workspace_premium;
        desc = "Gerçek meydan okuma";
        cells = "53+";
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _startGame(context, difficulty),
        child: Container(
          height: 95,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: color.withOpacity(.30),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),

              CircleAvatar(
                radius: 26,
                // ignore: deprecated_member_use
                backgroundColor: color.withOpacity(.20),
                child: Icon(icon, color: color, size: 30),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 16,
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(.75),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cells,
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "boş",
                    // ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(.70)),
                  ),
                ],
              ),

              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101820),

      appBar: AppBar(
        title: const Text(
          "Bulmaca Dünyası",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff101820),
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: .04,
                child: Column(
                  children: List.generate(
                    12,
                    (row) => Expanded(
                      child: Row(
                        children: List.generate(
                          8,
                          (col) => const Expanded(
                            child: Center(
                              child: Text(
                                "123456789",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: .05,
                child: Column(
                  children: List.generate(
                    12,
                    (i) => Expanded(
                      child: Row(
                        children: List.generate(
                          8,
                          (j) => Expanded(
                            child: Center(
                              child: Text(
                                "${Random().nextInt(9) + 1}",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.amber.withOpacity(.45),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: const [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "S",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              VerticalDivider(width: 1, color: Colors.black),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "U",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              VerticalDivider(width: 1, color: Colors.black),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "D",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.black),
                        Expanded(
                          child: Row(
                            children: const [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "O",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              VerticalDivider(width: 1, color: Colors.black),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "K",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              VerticalDivider(width: 1, color: Colors.black),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "U",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.black),
                        const Expanded(
                          child: Row(
                            children: [
                              Expanded(child: SizedBox()),
                              VerticalDivider(width: 1, color: Colors.black),
                              Expanded(child: SizedBox()),
                              VerticalDivider(width: 1, color: Colors.black),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Column(
                    children: [
                      const Text(
                        "SUDOKU",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Klasik 9×9 Sudoku Bulmacası",
                        style: TextStyle(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(.70),
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Zorluk Seç",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  _buildButton(context, "Kolay", "easy", Colors.green),

                  _buildButton(context, "Orta", "medium", Colors.orange),

                  _buildButton(context, "Zor", "hard", Colors.red),

                  _buildButton(context, "Uzman", "expert", Colors.purple),
                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.amber,
                          size: 34,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Nasıl Oynanır?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "Her satır, sütun ve 3×3 kutu içerisinde 1-9 arasındaki tüm sayılar yalnızca bir kez bulunmalıdır.",
                                style: TextStyle(
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(.75),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

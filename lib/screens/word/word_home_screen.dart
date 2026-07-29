import 'package:flutter/material.dart';
import '../../widgets/difficulty_card.dart';
import '../game/word_game_screen.dart';

class WordHomeScreen extends StatelessWidget {
  const WordHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Kelime Dünyası",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.menu_book, color: Colors.amber, size: 90),

            const SizedBox(height: 15),

            const Text(
              "Kelime Bulmaca",
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Kelime hazneni geliştir.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),

            const SizedBox(height: 35),

            DifficultyCard(
              color: Colors.green,
              icon: Icons.sentiment_satisfied,
              title: "Kolay",
              subtitle: "25.000+ Kelime",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const WordGameScreen(difficulty: "easy"),
                  ),
                );
              },
            ),

            DifficultyCard(
              color: Colors.orange,
              icon: Icons.psychology,
              title: "Orta",
              subtitle: "50.000+ Kelime",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const WordGameScreen(difficulty: "medium"),
                  ),
                );
              },
            ),

            DifficultyCard(
              color: Colors.red,
              icon: Icons.local_fire_department,
              title: "Zor",
              subtitle: "100.000+ Kelime",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const WordGameScreen(difficulty: "hard"),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

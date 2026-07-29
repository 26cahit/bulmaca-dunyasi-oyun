import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/player_service.dart';

class NumberLogicScreen extends StatefulWidget {
  const NumberLogicScreen({super.key});

  @override
  State<NumberLogicScreen> createState() => _NumberLogicScreenState();
}

class _NumberLogicScreenState extends State<NumberLogicScreen> {
  final Random random = Random();

  int currentQuestion = 0;
  int score = 0;

  int? selectedAnswer;

  bool answered = false;

  final List<Map<String, dynamic>> allQuestions = [
    {
      'question': '2, 4, 6, 8, ?',
      'answers': [9, 10, 11, 12],
      'correct': 10,
    },
    {
      'question': '3, 6, 12, 24, ?',
      'answers': [36, 42, 48, 52],
      'correct': 48,
    },
    {
      'question': '1, 4, 9, 16, ?',
      'answers': [20, 24, 25, 36],
      'correct': 25,
    },
    {
      'question': '5, 10, 20, 40, ?',
      'answers': [60, 70, 80, 100],
      'correct': 80,
    },
    {
      'question': '100, 90, 80, 70, ?',
      'answers': [50, 55, 60, 65],
      'correct': 60,
    },
  ];

  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();

    _saveCurrentGame();

    prepareQuestions();
  }

  Future<void> _saveCurrentGame() async {
    await PlayerService.saveLastGame(
      gameType: 'intelligence',
      section: 'number_logic',
    );
  }

  void prepareQuestions() {
    questions = List<Map<String, dynamic>>.from(allQuestions);

    questions.shuffle(random);

    currentQuestion = 0;
    score = 0;
    selectedAnswer = null;
    answered = false;
  }

  void selectAnswer(int answer) {
    if (answered) return;

    final int correctAnswer = questions[currentQuestion]['correct'] as int;

    setState(() {
      selectedAnswer = answer;
      answered = true;

      if (answer == correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (!answered) return;

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      showResult();
    }
  }

  void restartGame() {
    setState(() {
      prepareQuestions();
    });
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Test Tamamlandı',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '$score / ${questions.length} doğru cevap',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Tekrar Oyna',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final Map<String, dynamic> question = questions[currentQuestion];

    final List<int> answers = question['answers'] as List<int>;

    final int correctAnswer = question['correct'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sayı Mantığı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxHeight < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: compact ? 10 : 18,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Soru ${currentQuestion + 1}/${questions.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        'Puan: $score',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: compact ? 14 : 24),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: compact ? 25 : 38,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calculate_rounded,
                          color: Colors.amber,
                          size: 42,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Sıradaki sayıyı bul',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),

                        const SizedBox(height: 16),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            question['question'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: compact ? 14 : 22),

                  ...answers.map((answer) {
                    Color backgroundColor = const Color(0xFF1E293B);

                    Color borderColor = Colors.white12;

                    if (answered) {
                      if (answer == correctAnswer) {
                        backgroundColor = Colors.green.withValues(alpha: 0.18);

                        borderColor = Colors.green;
                      } else if (answer == selectedAnswer) {
                        backgroundColor = Colors.red.withValues(alpha: 0.18);

                        borderColor = Colors.red;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () {
                            selectAnswer(answer);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 17,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              answer.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: answered ? nextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        currentQuestion == questions.length - 1
                            ? 'SONUCU GÖR'
                            : 'SONRAKİ SORU',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

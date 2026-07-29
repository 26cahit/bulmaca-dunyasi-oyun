// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../services/player_service.dart';
import '../../services/sound_service.dart';

class QuickIntelligenceScreen extends StatefulWidget {
  const QuickIntelligenceScreen({super.key});

  @override
  State<QuickIntelligenceScreen> createState() =>
      _QuickIntelligenceScreenState();
}

class _QuickIntelligenceScreenState extends State<QuickIntelligenceScreen> {
  final Random random = Random();

  int score = 0;
  int questionNumber = 1;
  int timeLeft = 10;

  int firstNumber = 0;
  int secondNumber = 0;
  int correctAnswer = 0;

  List<int> answers = [];

  Timer? timer;

  bool answered = false;
  int? selectedAnswer;

  @override
  void initState() {
    super.initState();

    _saveCurrentGame();

    createQuestion();

    startTimer();
  }

  Future<void> _saveCurrentGame() async {
    await PlayerService.saveLastGame(
      gameType: 'intelligence',
      section: 'quick',
    );
  }

  void createQuestion() {
    firstNumber = random.nextInt(20) + 1;

    secondNumber = random.nextInt(20) + 1;

    correctAnswer = firstNumber + secondNumber;

    answers = [
      correctAnswer,
      correctAnswer + random.nextInt(5) + 1,
      correctAnswer - random.nextInt(5) - 1,
      correctAnswer + random.nextInt(10) + 5,
    ];

    answers = answers.toSet().toList();

    while (answers.length < 4) {
      final int newAnswer = correctAnswer + random.nextInt(15) - 7;

      if (!answers.contains(newAnswer)) {
        answers.add(newAnswer);
      }
    }

    answers.shuffle();

    answered = false;

    selectedAnswer = null;

    timeLeft = 10;
  }

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        SoundService.playTick();

        if (!mounted) {
          return;
        }

        setState(() {
          timeLeft--;
        });
      } else {
        nextQuestion();
      }
    });
  }

  Future<void> checkAnswer(int answer) async {
    if (answered) {
      return;
    }

    timer?.cancel();

    await SoundService.stopTick();

    final bool isCorrect = answer == correctAnswer;

    if (!mounted) {
      return;
    }

    if (isCorrect) {
      await context.read<PlayerProvider>().addReward(addXp: 10, addCoins: 5);
    }

    setState(() {
      answered = true;

      selectedAnswer = answer;

      if (isCorrect) {
        score++;
      }
    });

    if (isCorrect) {
      await SoundService.playCorrect();
    } else {
      await SoundService.playWrong();
    }
  }

  void nextQuestion() {
    if (questionNumber >= 10) {
      timer?.cancel();

      SoundService.stopTick();

      showResult();

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      questionNumber++;

      createQuestion();
    });

    startTimer();
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Test Tamamlandı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Puanın: $score / 10',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await context.read<PlayerProvider>().addReward(
                  addXp: score * 10,
                  addCoins: score * 5,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text(
                'GERİ DÖN',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color answerColor(int answer) {
    if (!answered) {
      return const Color(0xFF1E293B);
    }

    if (answer == correctAnswer) {
      return Colors.green.withValues(alpha: 0.25);
    }

    if (answer == selectedAnswer) {
      return Colors.red.withValues(alpha: 0.25);
    }

    return const Color(0xFF1E293B);
  }

  Color answerBorderColor(int answer) {
    if (!answered) {
      return Colors.white24;
    }

    if (answer == correctAnswer) {
      return Colors.green;
    }

    if (answer == selectedAnswer) {
      return Colors.red;
    }

    return Colors.white24;
  }

  @override
  void dispose() {
    timer?.cancel();

    SoundService.stopTick();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Hızlı Zeka',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soru $questionNumber/10',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  Text(
                    'Puan: $score',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.timer, color: Colors.amber, size: 45),

                    const SizedBox(height: 8),

                    Text(
                      '$timeLeft',
                      style: TextStyle(
                        color: timeLeft <= 3 ? Colors.red : Colors.amber,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      '$firstNumber + $secondNumber = ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView.separated(
                  itemCount: answers.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final int answer = answers[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        checkAnswer(answer);
                      },
                      child: Container(
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: answerColor(answer),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: answerBorderColor(answer),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$answer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: answered ? nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'SONRAKİ SORU',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/player_service.dart';
import '../../services/sound_service.dart';

class MixedTestScreen extends StatefulWidget {
  const MixedTestScreen({super.key});

  @override
  State<MixedTestScreen> createState() => _MixedTestScreenState();
}

class _MixedTestScreenState extends State<MixedTestScreen> {
  final Random random = Random();

  int score = 0;
  int questionNumber = 1;
  int timeLeft = 10;

  Timer? timer;

  String question = '';
  String category = '';

  int correctAnswer = 0;

  List<int> answers = [];

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
      section: 'mixed',
    );
  }

  void createQuestion() {
    final int questionType = random.nextInt(4);

    if (questionType == 0) {
      createAdditionQuestion();
    } else if (questionType == 1) {
      createSubtractionQuestion();
    } else if (questionType == 2) {
      createSequenceQuestion();
    } else {
      createLogicQuestion();
    }

    createAnswers();

    answered = false;

    selectedAnswer = null;

    timeLeft = 10;
  }

  void createAdditionQuestion() {
    final int firstNumber = random.nextInt(30) + 1;

    final int secondNumber = random.nextInt(30) + 1;

    question = '$firstNumber + $secondNumber = ?';

    correctAnswer = firstNumber + secondNumber;

    category = 'Sayı Mantığı';
  }

  void createSubtractionQuestion() {
    final int firstNumber = random.nextInt(30) + 20;

    final int secondNumber = random.nextInt(20) + 1;

    question = '$firstNumber - $secondNumber = ?';

    correctAnswer = firstNumber - secondNumber;

    category = 'Hızlı Zeka';
  }

  void createSequenceQuestion() {
    final int startNumber = random.nextInt(10) + 1;

    final int difference = random.nextInt(5) + 2;

    final int secondNumber = startNumber + difference;

    final int thirdNumber = secondNumber + difference;

    final int fourthNumber = thirdNumber + difference;

    correctAnswer = fourthNumber + difference;

    question = '$startNumber, $secondNumber, $thirdNumber, $fourthNumber, ?';

    category = 'Sayı Örüntüsü';
  }

  void createLogicQuestion() {
    final int firstNumber = random.nextInt(8) + 2;

    correctAnswer = firstNumber * 2;

    question = '$firstNumber sayısının 2 katı kaçtır?';

    category = 'Mantık Sorusu';
  }

  void createAnswers() {
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

    answers.shuffle(random);
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
            'Karışık Test Tamamlandı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Puanın: $score / 10',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () {
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
          'Karışık Test',
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

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 42,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$timeLeft',
                      style: TextStyle(
                        color: timeLeft <= 3 ? Colors.red : Colors.amber,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  itemCount: answers.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, index) {
                    final int answer = answers[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        checkAnswer(answer);
                      },
                      child: Container(
                        height: 68,
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
                            fontSize: 23,
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

import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/player_service.dart';
import '../../services/sound_service.dart';
import '../../utils/responsive.dart';

class LogicQuestionsScreen extends StatefulWidget {
  const LogicQuestionsScreen({super.key});

  @override
  State<LogicQuestionsScreen> createState() => _LogicQuestionsScreenState();
}

class _LogicQuestionsScreenState extends State<LogicQuestionsScreen> {
  final Random random = Random();

  int currentQuestion = 0;
  int score = 0;

  int? selectedAnswer;
  bool answered = false;

  final List<Map<String, dynamic>> allQuestions = [
    {
      'question':
          'Ali, Mehmet\'ten uzundur. Mehmet, Can\'dan uzundur. En uzun kimdir?',
      'answers': ['Ali', 'Mehmet', 'Can', 'Bilinemez'],
      'correct': 0,
    },
    {
      'question': 'Tüm kediler hayvandır. Minnoş bir kedidir. Minnoş nedir?',
      'answers': ['Kuş', 'Hayvan', 'Balık', 'Bitki'],
      'correct': 1,
    },
    {
      'question': 'Bugün salıysa 3 gün sonra hangi gündür?',
      'answers': ['Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'],
      'correct': 2,
    },
    {
      'question': 'Bir yarışta ikinci kişiyi geçersen kaçıncı olursun?',
      'answers': ['Birinci', 'İkinci', 'Üçüncü', 'Sonuncu'],
      'correct': 1,
    },
    {
      'question':
          '5 makine 5 dakikada 5 ürün yapıyor. 1 makine 5 dakikada kaç ürün yapar?',
      'answers': ['1', '5', '10', '25'],
      'correct': 0,
    },
    {
      'question':
          'Bir çiftçinin 10 koyunu vardı. 3 tanesi hariç hepsi kaçtı. Kaç koyun kaldı?',
      'answers': ['3', '7', '10', '0'],
      'correct': 0,
    },
    {
      'question':
          'Saat 12.00\'de başlayan film 2 saat 30 dakika sürerse kaçta biter?',
      'answers': ['13.30', '14.00', '14.30', '15.30'],
      'correct': 2,
    },
    {
      'question':
          'Bir kitap ve kalem toplam 110 TL. Kitap kalemden 100 TL pahalı. Kalem kaç TL?',
      'answers': ['5 TL', '10 TL', '15 TL', '20 TL'],
      'correct': 0,
    },
    {
      'question':
          'Bir odada 4 köşe vardır. Her köşede bir kedi var. Odada kaç kedi vardır?',
      'answers': ['4', '8', '12', '16'],
      'correct': 0,
    },
    {
      'question':
          'Ayşe\'nin 3 kız kardeşi var. Her kız kardeşin 1 erkek kardeşi var. Ayşe\'nin kaç erkek kardeşi vardır?',
      'answers': ['1', '3', '4', '6'],
      'correct': 0,
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
      section: 'logic',
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

  Future<void> selectAnswer(int index) async {
    if (answered) return;

    final int correctIndex = questions[currentQuestion]['correct'] as int;

    setState(() {
      selectedAnswer = index;
      answered = true;

      if (index == correctIndex) {
        score++;
      }
    });

    if (index == correctIndex) {
      await SoundService.playCorrect();
    } else {
      await SoundService.playWrong();
    }
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
            'Mantık Testi Tamamlandı',
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
    final Responsive responsive = Responsive(context);

    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final Map<String, dynamic> question = questions[currentQuestion];

    final List<String> answers = question['answers'] as List<String>;

    final int correctIndex = question['correct'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mantık Soruları',
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.font(22),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxHeight < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: responsive.smallGap,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Soru ${currentQuestion + 1}/${questions.length}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: responsive.font(15),
                          ),
                        ),
                      ),
                      Text(
                        'Puan: $score',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: responsive.font(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: responsive.mediumGap),

                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: compact ? 150 : 180),
                    padding: EdgeInsets.all(responsive.mediumGap),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.extension_rounded,
                          color: Colors.amber,
                          size: responsive.font(40),
                        ),

                        SizedBox(height: responsive.mediumGap),

                        Text(
                          question['question'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.font(20),
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.mediumGap),

                  ...List.generate(answers.length, (index) {
                    Color backgroundColor = const Color(0xFF1E293B);

                    Color borderColor = Colors.white12;

                    if (answered) {
                      if (index == correctIndex) {
                        backgroundColor = Colors.green.withValues(alpha: 0.18);

                        borderColor = Colors.green;
                      } else if (index == selectedAnswer) {
                        backgroundColor = Colors.red.withValues(alpha: 0.18);

                        borderColor = Colors.red;
                      }
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: responsive.smallGap),
                      child: Material(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            selectAnswer(index);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 54),
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.mediumGap,
                              vertical: responsive.smallGap,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                answers[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsive.font(17),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: responsive.smallGap),

                  SizedBox(
                    width: double.infinity,
                    height: responsive.clampHeight(0.06, min: 46, max: 54),
                    child: ElevatedButton(
                      onPressed: answered ? nextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currentQuestion == questions.length - 1
                              ? 'SONUCU GÖR'
                              : 'SONRAKİ SORU',
                          style: TextStyle(
                            fontSize: responsive.font(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: responsive.mediumGap),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

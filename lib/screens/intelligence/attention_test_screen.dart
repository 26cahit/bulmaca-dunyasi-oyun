import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/player_service.dart';
import '../../services/sound_service.dart';
import '../../utils/responsive.dart';

class AttentionTestScreen extends StatefulWidget {
  const AttentionTestScreen({super.key});

  @override
  State<AttentionTestScreen> createState() => _AttentionTestScreenState();
}

class _AttentionTestScreenState extends State<AttentionTestScreen> {
  final Random _random = Random();

  int currentQuestion = 1;
  int score = 0;

  final int totalQuestions = 10;

  late List<String> symbols;
  late int differentIndex;

  bool answered = false;
  int? selectedIndex;

  final List<Map<String, String>> symbolGroups = [
    {'normal': '●', 'different': '○'},
    {'normal': '▲', 'different': '△'},
    {'normal': '■', 'different': '□'},
    {'normal': '◆', 'different': '◇'},
    {'normal': '★', 'different': '☆'},
    {'normal': '♥', 'different': '♡'},
  ];

  @override
  void initState() {
    super.initState();

    _saveCurrentGame();

    _prepareQuestion();
  }

  Future<void> _saveCurrentGame() async {
    await PlayerService.saveLastGame(
      gameType: 'intelligence',
      section: 'attention',
    );
  }

  void _prepareQuestion() {
    final Map<String, String> group =
        symbolGroups[_random.nextInt(symbolGroups.length)];

    final String normalSymbol = group['normal']!;

    final String differentSymbol = group['different']!;

    const int itemCount = 20;

    differentIndex = _random.nextInt(itemCount);

    symbols = List.generate(itemCount, (index) {
      if (index == differentIndex) {
        return differentSymbol;
      }

      return normalSymbol;
    });

    answered = false;

    selectedIndex = null;
  }

  Future<void> _selectSymbol(int index) async {
    if (answered) return;

    setState(() {
      answered = true;

      selectedIndex = index;

      if (index == differentIndex) {
        score++;
      }
    });

    if (index == differentIndex) {
      await SoundService.playCorrect();
    } else {
      await SoundService.playWrong();
    }
  }

  void _nextQuestion() {
    if (!answered) return;

    if (currentQuestion < totalQuestions) {
      setState(() {
        currentQuestion++;

        _prepareQuestion();
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
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
            'Dikkat Testi Tamamlandı',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '$score / $totalQuestions doğru cevap',
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

                setState(() {
                  currentQuestion = 1;

                  score = 0;

                  _prepareQuestion();
                });
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

    final double gridSpacing = responsive.clampWidth(0.025, min: 7, max: 12);

    final double symbolFontSize = responsive.font(
      34,
      minScale: 0.75,
      maxScale: 1.10,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Dikkat Testi',
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
                          'Soru $currentQuestion/$totalQuestions',
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
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.mediumGap,
                      vertical: responsive.mediumGap,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: Colors.amber,
                          size: responsive.font(38),
                        ),

                        SizedBox(height: responsive.smallGap),

                        Text(
                          'Farklı olan şekli bul',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.font(20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: responsive.smallGap),

                        Text(
                          'Diğerlerinden farklı olan şekle dokun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: responsive.font(14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.mediumGap),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: symbols.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      Color backgroundColor = const Color(0xFF1E293B);

                      Color borderColor = Colors.white12;

                      if (answered) {
                        if (index == differentIndex) {
                          backgroundColor = Colors.green.withValues(
                            alpha: 0.18,
                          );

                          borderColor = Colors.green;
                        } else if (index == selectedIndex) {
                          backgroundColor = Colors.red.withValues(alpha: 0.18);

                          borderColor = Colors.red;
                        }
                      }

                      return Material(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            _selectSymbol(index);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  symbols[index],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: symbolFontSize,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: responsive.mediumGap),

                  SizedBox(
                    width: double.infinity,
                    height: responsive.clampHeight(0.06, min: 46, max: 54),
                    child: ElevatedButton(
                      onPressed: answered ? _nextQuestion : null,
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
                          currentQuestion == totalQuestions
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

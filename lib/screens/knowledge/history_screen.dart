import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import '../../services/player_service.dart';
import '../../services/sound_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Random random = Random();

  final List<Map<String, dynamic>> allQuestions = [
    {
      'question': 'Türkiye Cumhuriyeti hangi yıl ilan edildi?',
      'answers': ['1919', '1920', '1923', '1938'],
      'correct': 2,
    },
    {
      'question': 'İstanbul hangi yıl fethedildi?',
      'answers': ['1071', '1453', '1517', '1923'],
      'correct': 1,
    },
    {
      'question': 'Malazgirt Meydan Muharebesi hangi yıl yapıldı?',
      'answers': ['1071', '1299', '1453', '1517'],
      'correct': 0,
    },
    {
      'question': 'Osmanlı Devleti\'nin kurucusu kimdir?',
      'answers': [
        'Orhan Gazi',
        'Osman Gazi',
        'Yıldırım Bayezid',
        'Fatih Sultan Mehmet',
      ],
      'correct': 1,
    },
    {
      'question': 'Kurtuluş Savaşı hangi antlaşmayla sona erdi?',
      'answers': [
        'Sevr Antlaşması',
        'Mondros Ateşkesi',
        'Lozan Antlaşması',
        'Ankara Antlaşması',
      ],
      'correct': 2,
    },
    {
      'question': 'Fransız İhtilali hangi yıl başladı?',
      'answers': ['1453', '1789', '1815', '1914'],
      'correct': 1,
    },
    {
      'question': 'I. Dünya Savaşı hangi yıl başladı?',
      'answers': ['1908', '1914', '1918', '1923'],
      'correct': 1,
    },
    {
      'question': 'TBMM hangi yıl açıldı?',
      'answers': ['1919', '1920', '1921', '1923'],
      'correct': 1,
    },
    {
      'question': 'Mısır piramitleri hangi uygarlık tarafından yapılmıştır?',
      'answers': ['Romalılar', 'Antik Mısırlılar', 'Hititler', 'Sümerler'],
      'correct': 1,
    },
    {
      'question': 'Yazıyı ilk kullanan uygarlıklardan biri hangisidir?',
      'answers': ['Sümerler', 'Osmanlılar', 'Bizanslılar', 'Moğollar'],
      'correct': 0,
    },
  ];

  List<Map<String, dynamic>> questions = [];

  int questionNumber = 0;
  int score = 0;

  int earnedXp = 0;
  int earnedCoins = 0;

  bool answered = false;
  bool helpUsed = false;

  int? selectedAnswer;

  final Set<int> hiddenAnswers = {};

  @override
  void initState() {
    super.initState();

    _saveCurrentGame();

    _prepareQuestions();
  }

  Future<void> _saveCurrentGame() async {
    await PlayerService.saveLastGame(gameType: 'knowledge', section: 'history');
  }

  void _prepareQuestions() {
    questions = List<Map<String, dynamic>>.from(allQuestions);

    questions.shuffle(random);

    questionNumber = 0;
    score = 0;

    earnedXp = 0;
    earnedCoins = 0;

    answered = false;
    helpUsed = false;

    selectedAnswer = null;

    hiddenAnswers.clear();
  }

  Future<void> checkAnswer(int answerIndex) async {
    if (answered) {
      return;
    }

    if (hiddenAnswers.contains(answerIndex)) {
      return;
    }

    final int correctAnswer = questions[questionNumber]['correct'];

    final bool isCorrect = answerIndex == correctAnswer;

    setState(() {
      answered = true;
      selectedAnswer = answerIndex;

      if (isCorrect) {
        score++;

        earnedXp += 10;

        earnedCoins += 5;
      }
    });

    if (isCorrect) {
      await SoundService.playCorrect();
    } else {
      await SoundService.playWrong();
    }
  }

  Future<void> useHelp() async {
    if (answered) {
      return;
    }

    if (helpUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu soruda yardım zaten kullanıldı.'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final player = context.read<PlayerProvider>();

    const int helpPrice = 25;

    if (player.coins < helpPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yeterli jetonun yok. Yardım için '
            '$helpPrice jeton gerekiyor. '
            'Şu an ${player.coins} jetonun var.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final int remainingCoins = player.coins - helpPrice;

        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yardım Kullan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '${player.coins} jetonun var.\n\n'
            'Bu yardımın değeri $helpPrice jeton.\n\n'
            'Yardımı kullanırsan $remainingCoins jetonun kalacak.\n\n'
            'İki yanlış seçenek kaldırılacak.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'VAZGEÇ',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                '25 JETON KULLAN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final int correctAnswer = questions[questionNumber]['correct'];

    final List<int> wrongAnswers = [];

    for (int i = 0; i < questions[questionNumber]['answers'].length; i++) {
      if (i != correctAnswer) {
        wrongAnswers.add(i);
      }
    }

    wrongAnswers.shuffle(random);

    await player.addReward(addXp: 0, addCoins: -helpPrice);

    if (!mounted) {
      return;
    }

    setState(() {
      helpUsed = true;

      hiddenAnswers.clear();

      hiddenAnswers.add(wrongAnswers[0]);
      hiddenAnswers.add(wrongAnswers[1]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💡 İki yanlış seçenek kaldırıldı. '
          '${player.coins} jetonun kaldı.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void nextQuestion() {
    if (questionNumber >= questions.length - 1) {
      showResult();

      return;
    }

    setState(() {
      questionNumber++;

      answered = false;

      selectedAnswer = null;

      helpUsed = false;

      hiddenAnswers.clear();
    });
  }

  Future<void> showResult() async {
    final player = context.read<PlayerProvider>();

    await player.addReward(addXp: earnedXp, addCoins: earnedCoins);

    if (!mounted) {
      return;
    }

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
            '🎉 Test Tamamlandı',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Puanın',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$score / ${questions.length}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Kazanılan XP',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                        ),
                        Text(
                          '+$earnedXp XP',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Kazanılan Jeton',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                        ),
                        Text(
                          '+$earnedCoins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Toplam Jeton: ${player.coins}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 13,
                ),
              ),
              child: const Text(
                'GERİ DÖN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Color answerColor(int index) {
    if (!answered) {
      return const Color(0xFF1E293B);
    }

    final int correctAnswer = questions[questionNumber]['correct'];

    if (index == correctAnswer) {
      return Colors.green.withValues(alpha: 0.25);
    }

    if (index == selectedAnswer) {
      return Colors.red.withValues(alpha: 0.25);
    }

    return const Color(0xFF1E293B);
  }

  Color answerBorderColor(int index) {
    if (!answered) {
      return Colors.white24;
    }

    final int correctAnswer = questions[questionNumber]['correct'];

    if (index == correctAnswer) {
      return Colors.green;
    }

    if (index == selectedAnswer) {
      return Colors.red;
    }

    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final Map<String, dynamic> currentQuestion = questions[questionNumber];

    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Tarih',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Soru ${questionNumber + 1}/${questions.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    '💰 ${player.coins}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      color: Colors.amber,
                      size: 48,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      currentQuestion['question'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: answered || helpUsed ? null : useHelp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: BorderSide(
                            color: answered || helpUsed
                                ? Colors.white24
                                : Colors.amber,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.lightbulb),
                        label: Text(
                          helpUsed
                              ? 'YARDIM KULLANILDI'
                              : 'İKİ ŞIKKI KALDIR • 25 JETON',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: currentQuestion['answers'].length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final String answer = currentQuestion['answers'][index];

                    final bool isHidden = hiddenAnswers.contains(index);

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: isHidden ? 0.15 : 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: isHidden
                            ? null
                            : () {
                                checkAnswer(index);
                              },
                        child: Container(
                          height: 72,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isHidden
                                ? Colors.white.withValues(alpha: 0.03)
                                : answerColor(index),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isHidden
                                  ? Colors.white10
                                  : answerBorderColor(index),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            isHidden ? 'ELENDİ' : answer,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isHidden ? Colors.white38 : Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
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
                  child: Text(
                    questionNumber == questions.length - 1
                        ? 'TESTİ BİTİR'
                        : 'SONRAKİ SORU',
                    style: const TextStyle(
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
  }
}

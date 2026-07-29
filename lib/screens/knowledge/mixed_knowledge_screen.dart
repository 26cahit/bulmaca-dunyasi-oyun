import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import '../../services/player_service.dart';
import '../../services/sound_service.dart';

class MixedKnowledgeScreen extends StatefulWidget {
  const MixedKnowledgeScreen({super.key});

  @override
  State<MixedKnowledgeScreen> createState() => _MixedKnowledgeScreenState();
}

class _MixedKnowledgeScreenState extends State<MixedKnowledgeScreen> {
  final Random random = Random();

  final List<Map<String, dynamic>> allQuestions = [
    {
      'category': 'Coğrafya',
      'question': 'Türkiye\'nin başkenti neresidir?',
      'answers': ['İstanbul', 'Ankara', 'İzmir', 'Bursa'],
      'correct': 1,
    },
    {
      'category': 'Coğrafya',
      'question': 'Dünyanın en büyük okyanusu hangisidir?',
      'answers': [
        'Atlas Okyanusu',
        'Hint Okyanusu',
        'Pasifik Okyanusu',
        'Arktik Okyanusu',
      ],
      'correct': 2,
    },
    {
      'category': 'Coğrafya',
      'question': 'Avustralya\'nın başkenti neresidir?',
      'answers': ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
      'correct': 2,
    },
    {
      'category': 'Tarih',
      'question': 'Türkiye Cumhuriyeti hangi yıl ilan edildi?',
      'answers': ['1919', '1920', '1923', '1938'],
      'correct': 2,
    },
    {
      'category': 'Tarih',
      'question': 'İstanbul hangi yıl fethedildi?',
      'answers': ['1071', '1453', '1517', '1923'],
      'correct': 1,
    },
    {
      'category': 'Tarih',
      'question': 'TBMM hangi yıl açıldı?',
      'answers': ['1919', '1920', '1921', '1923'],
      'correct': 1,
    },
    {
      'category': 'Bilim',
      'question': 'Suyun kimyasal formülü hangisidir?',
      'answers': ['CO2', 'H2O', 'O2', 'NaCl'],
      'correct': 1,
    },
    {
      'category': 'Bilim',
      'question': 'İnsan kalbi kaç odacıktan oluşur?',
      'answers': ['2', '3', '4', '5'],
      'correct': 2,
    },
    {
      'category': 'Bilim',
      'question': 'Elektrik akımının birimi hangisidir?',
      'answers': ['Volt', 'Watt', 'Amper', 'Ohm'],
      'correct': 2,
    },
    {
      'category': 'Sanat ve Edebiyat',
      'question': 'Mona Lisa tablosunun ressamı kimdir?',
      'answers': [
        'Pablo Picasso',
        'Leonardo da Vinci',
        'Vincent van Gogh',
        'Claude Monet',
      ],
      'correct': 1,
    },
    {
      'category': 'Sanat ve Edebiyat',
      'question': 'İnce Memed romanının yazarı kimdir?',
      'answers': [
        'Orhan Pamuk',
        'Sabahattin Ali',
        'Yaşar Kemal',
        'Kemal Tahir',
      ],
      'correct': 2,
    },
    {
      'category': 'Sanat ve Edebiyat',
      'question': 'Kaplumbağa Terbiyecisi tablosunun ressamı kimdir?',
      'answers': [
        'İbrahim Çallı',
        'Osman Hamdi Bey',
        'Şeker Ahmet Paşa',
        'Bedri Rahmi Eyüboğlu',
      ],
      'correct': 1,
    },
  ];

  List<Map<String, dynamic>> questions = [];

  int questionNumber = 0;
  int score = 0;
  int coins = 0;

  bool answered = false;
  bool hintUsed = false;

  int? selectedAnswer;

  final Set<int> hiddenAnswers = {};

  @override
  void initState() {
    super.initState();

    createMixedQuestions();
    loadCoins();
  }

  void createMixedQuestions() {
    final shuffledQuestions = List<Map<String, dynamic>>.from(allQuestions);

    shuffledQuestions.shuffle(random);

    questions = shuffledQuestions.take(10).toList();
  }

  Future<void> loadCoins() async {
    final savedCoins = await PlayerService.getCoins();

    if (!mounted) {
      return;
    }

    setState(() {
      coins = savedCoins;
    });
  }

  Future<void> checkAnswer(int answerIndex) async {
    if (answered) {
      return;
    }

    if (hiddenAnswers.contains(answerIndex)) {
      return;
    }

    final int correctAnswer = questions[questionNumber]['correct'];

    setState(() {
      answered = true;
      selectedAnswer = answerIndex;

      if (answerIndex == correctAnswer) {
        score++;
      }
    });

    if (answerIndex == correctAnswer) {
      await SoundService.playCorrect();

      int currentXP = await PlayerService.getXP();
      int currentCoins = await PlayerService.getCoins();

      currentXP += 10;
      currentCoins += 5;

      await PlayerService.saveXP(currentXP);
      await PlayerService.saveCoins(currentCoins);

      if (!mounted) {
        return;
      }

      setState(() {
        coins = currentCoins;
      });

      await context.read<PlayerProvider>().loadPlayer();
    } else {
      await SoundService.playWrong();
    }
  }

  Future<void> useHint() async {
    if (answered || hintUsed) {
      return;
    }

    final int currentCoins = await PlayerService.getCoins();

    if (!mounted) {
      return;
    }

    if (currentCoins < 25) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              'Yetersiz Jeton',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Bu yardım 25 jeton değerindedir.\n\n'
              'Mevcut jetonun: $currentCoins\n\n'
              'Daha kolay sorular çözerek jeton kazanabilirsin.',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'TAMAM',
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

      return;
    }

    final bool? useCoin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            '💡 İpucu Kullan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bu yardım 25 jeton değerindedir.\n\n'
            'Şu an $currentCoins jetonun var.\n\n'
            'Kullanırsan ${currentCoins - 25} jetonun kalacak.\n\n'
            'İki yanlış seçenek kaldırılacak.',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
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

    if (useCoin != true) {
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

    final int newCoins = currentCoins - 25;

    await PlayerService.saveCoins(newCoins);

    if (!mounted) {
      return;
    }

    setState(() {
      coins = newCoins;
      hintUsed = true;

      hiddenAnswers.add(wrongAnswers[0]);
      hiddenAnswers.add(wrongAnswers[1]);
    });

    await context.read<PlayerProvider>().loadPlayer();
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
      hintUsed = false;
      hiddenAnswers.clear();
    });
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Karışık Bilgi Tamamlandı',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Puanın: $score / ${questions.length}\n\n'
            '⭐ Kazandığın XP: ${score * 10}\n'
            '💰 Kazandığın Jeton: ${score * 5}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
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

    final currentQuestion = questions[questionNumber];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Karışık Bilgi',
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
                    '💰 $coins',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 18),
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
                  currentQuestion['category'],
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 46,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      currentQuestion['question'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: answered || hintUsed ? null : useHint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withValues(alpha: 0.18),
                          foregroundColor: Colors.amber,
                          disabledBackgroundColor: Colors.white10,
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.lightbulb),
                        label: const Text(
                          'İPUCU • 25 JETON',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView.separated(
                  itemCount: currentQuestion['answers'].length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final String answer = currentQuestion['answers'][index];

                    final bool hidden = hiddenAnswers.contains(index);

                    return AnimatedOpacity(
                      opacity: hidden ? 0.15 : 1,
                      duration: const Duration(milliseconds: 400),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: hidden
                            ? null
                            : () {
                                checkAnswer(index);
                              },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 68),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: answerColor(index),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: answerBorderColor(index),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            hidden ? 'ELENDİ' : answer,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hidden ? Colors.white38 : Colors.white,
                              fontSize: 20,
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

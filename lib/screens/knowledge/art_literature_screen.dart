import 'package:flutter/material.dart';
import '../../services/sound_service.dart';

class ArtLiteratureScreen extends StatefulWidget {
  const ArtLiteratureScreen({super.key});

  @override
  State<ArtLiteratureScreen> createState() => _ArtLiteratureScreenState();
}

class _ArtLiteratureScreenState extends State<ArtLiteratureScreen> {
  final List<Map<String, dynamic>> questions = [
    {
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
      'question': 'Romeo ve Juliet adlı eserin yazarı kimdir?',
      'answers': [
        'William Shakespeare',
        'Victor Hugo',
        'Dostoyevski',
        'Tolstoy',
      ],
      'correct': 0,
    },
    {
      'question': 'Yıldızlı Gece tablosunu kim yapmıştır?',
      'answers': [
        'Vincent van Gogh',
        'Salvador Dali',
        'Pablo Picasso',
        'Rembrandt',
      ],
      'correct': 0,
    },
    {
      'question': 'Kürk Mantolu Madonna romanının yazarı kimdir?',
      'answers': [
        'Yaşar Kemal',
        'Sabahattin Ali',
        'Orhan Kemal',
        'Reşat Nuri Güntekin',
      ],
      'correct': 1,
    },
    {
      'question': 'Suç ve Ceza romanının yazarı kimdir?',
      'answers': ['Tolstoy', 'Victor Hugo', 'Dostoyevski', 'Franz Kafka'],
      'correct': 2,
    },
    {
      'question': 'Guernica tablosunun ressamı kimdir?',
      'answers': [
        'Claude Monet',
        'Pablo Picasso',
        'Leonardo da Vinci',
        'Vincent van Gogh',
      ],
      'correct': 1,
    },
    {
      'question': 'Çalıkuşu romanının yazarı kimdir?',
      'answers': [
        'Halide Edib Adıvar',
        'Reşat Nuri Güntekin',
        'Yakup Kadri Karaosmanoğlu',
        'Namık Kemal',
      ],
      'correct': 1,
    },
    {
      'question': 'Sefiller romanının yazarı kimdir?',
      'answers': ['Victor Hugo', 'Tolstoy', 'Franz Kafka', 'Albert Camus'],
      'correct': 0,
    },
    {
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

  int questionNumber = 0;
  int score = 0;

  bool answered = false;
  int? selectedAnswer;

  Future<void> checkAnswer(int answerIndex) async {
    if (answered) return;

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
    } else {
      await SoundService.playWrong();
    }
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
    });
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Test Tamamlandı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Puanın: $score / ${questions.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
    final currentQuestion = questions[questionNumber];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Sanat ve Edebiyat',
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
                    'Soru ${questionNumber + 1}/${questions.length}',
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.palette, color: Colors.amber, size: 48),
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

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        checkAnswer(index);
                      },
                      child: Container(
                        height: 72,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: answerColor(index),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: answerBorderColor(index),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          answer,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
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

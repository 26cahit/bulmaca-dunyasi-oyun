import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../data/word_data.dart';
import '../../providers/player_provider.dart';
import '../../services/player_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/wheel/wheel_widget.dart';
import 'package:firebase_database/firebase_database.dart';

class WordGameScreen extends StatefulWidget {
  final String difficulty;
  final bool isMultiplayer;
  final String? roomCode;
  final String? playerId;
  const WordGameScreen({
    super.key,
    required this.difficulty,
    this.isMultiplayer = false,
    this.roomCode,
    this.playerId,
  });

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen> {
  String currentWord = "";
  String currentHint = "";

  WordItem? currentItem;

  List<String> hiddenWord = [];

  List<WordItem> shuffledWords = [];

  List<int> questionOrder = [];

  int currentWordIndex = 0;

  int xp = 0;
  int coins = 0;
  int level = 1;

  Set<String> usedLetters = {};

  bool loadingGame = true;
  int guessChance = 2;

  DatabaseReference? roomRef;

  StreamSubscription<DatabaseEvent>? roomListener;

  bool gameFinished = false;

  final TextEditingController guessController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _initializeGame();

    if (widget.isMultiplayer && widget.roomCode != null) {
      roomRef = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}");

      listenPlayers();
    }
  }

  Future<void> _initializeGame() async {
    await loadPlayerData();

    if (widget.isMultiplayer) {
      await _createNewGame();
    } else {
      await _loadOrCreateGame();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loadingGame = false;
    });
  }

  List<WordItem> _getDifficultyWords() {
    if (widget.difficulty == "easy") {
      return List<WordItem>.from(WordData.easyWords);
    }

    if (widget.difficulty == "medium") {
      return List<WordItem>.from(WordData.mediumWords);
    }

    return List<WordItem>.from(WordData.hardWords);
  }

  Future<void> _loadOrCreateGame() async {
    final List<WordItem> sourceWords = _getDifficultyWords();

    final Map<String, dynamic>? progress = await PlayerService.getGameProgress(
      gameType: 'word',
      section: 'word_game',
      difficulty: widget.difficulty,
    );

    if (progress != null) {
      final dynamic savedOrder = progress['questionOrder'];

      final dynamic savedExtraData = progress['extraData'];

      if (savedOrder is List) {
        questionOrder = savedOrder
            .map((item) => (item as num).toInt())
            .where((index) => index >= 0 && index < sourceWords.length)
            .toList();
      }

      if (questionOrder.length == sourceWords.length) {
        shuffledWords = questionOrder
            .map((index) => sourceWords[index])
            .toList();

        currentWordIndex = (progress['questionNumber'] as num?)?.toInt() ?? 0;

        if (currentWordIndex < 0 || currentWordIndex >= shuffledWords.length) {
          currentWordIndex = 0;
        }

        if (savedExtraData is Map) {
          final Map<String, dynamic> extraData = Map<String, dynamic>.from(
            savedExtraData,
          );

          guessChance = (extraData['guessChance'] as num?)?.toInt() ?? 2;

          final dynamic savedLetters = extraData['usedLetters'];

          if (savedLetters is List) {
            usedLetters = savedLetters.map((item) => item.toString()).toSet();
          }
        }

        _loadSavedWord();

        await PlayerService.saveLastGame(
          gameType: 'word',
          section: 'word_game',
          difficulty: widget.difficulty,
        );

        return;
      }
    }

    await _createNewGame();
  }

  Future<void> _createNewGame() async {
    final List<WordItem> sourceWords = _getDifficultyWords();

    questionOrder = List<int>.generate(sourceWords.length, (index) => index);

    questionOrder.shuffle(Random());

    shuffledWords = questionOrder.map((index) => sourceWords[index]).toList();

    currentWordIndex = 0;

    usedLetters.clear();

    guessChance = 2;

    loadCurrentWord();

    await _saveProgress();
  }

  void _loadSavedWord() {
    if (shuffledWords.isEmpty) {
      return;
    }

    currentItem = shuffledWords[currentWordIndex];

    currentWord = currentItem!.word;

    currentHint = currentItem!.hint;

    prepareHiddenWord();

    for (final String letter in usedLetters) {
      for (int i = 0; i < currentWord.length; i++) {
        if (currentWord[i] == letter) {
          hiddenWord[i] = letter;
        }
      }
    }

    guessController.clear();
  }

  Future<void> _saveProgress() async {
    if (shuffledWords.isEmpty) {
      return;
    }

    await PlayerService.saveGameProgress(
      gameType: 'word',
      section: 'word_game',
      difficulty: widget.difficulty,
      questionNumber: currentWordIndex,
      score: 0,
      earnedXp: 0,
      earnedCoins: 0,
      questionOrder: questionOrder,
      extraData: {
        'guessChance': guessChance,
        'usedLetters': usedLetters.toList(),
      },
    );
  }

  void listenPlayers() {
    roomListener = roomRef?.child("players").onValue.listen((event) async {
      if (!mounted) return;

      if (gameFinished) return;

      if (!event.snapshot.exists) return;

      final Map<dynamic, dynamic> players = Map<dynamic, dynamic>.from(
        event.snapshot.value as Map,
      );

      final int playerCount = players.length;

      if (playerCount <= 1) {
        gameFinished = true;

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Diğer oyuncu oyundan ayrıldı. Kazandın!"),
          ),
        );

        final player = Provider.of<PlayerProvider>(context, listen: false);

        await player.addReward(addXp: 100, addCoins: 50);
      }
    });
  }

  @override
  void dispose() {
    roomListener?.cancel();

    guessController.dispose();

    super.dispose();
  }

  Future<void> loadPlayerData() async {
    xp = await PlayerService.getXP();

    coins = await PlayerService.getCoins();

    level = await PlayerService.getLevel();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void loadCurrentWord() {
    if (shuffledWords.isEmpty) {
      return;
    }

    currentItem = shuffledWords[currentWordIndex];

    currentWord = currentItem!.word;

    currentHint = currentItem!.hint;

    prepareHiddenWord();

    usedLetters.clear();

    guessChance = 2;

    guessController.clear();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> nextWord() async {
    if (shuffledWords.isEmpty) {
      return;
    }

    currentWordIndex++;

    if (currentWordIndex >= shuffledWords.length) {
      await PlayerService.clearGameProgress(
        gameType: 'word',
        section: 'word_game',
        difficulty: widget.difficulty,
      );

      await _createNewGame();

      return;
    }

    loadCurrentWord();

    await _saveProgress();
  }

  Future<void> guessWord() async {
    if (guessChance == 0) {
      return;
    }

    final String guess = guessController.text.trim().toUpperCase();

    if (guess.isEmpty) {
      return;
    }

    if (guess == currentWord) {
      guessController.clear();

      hiddenWord = currentWord.split("");

      setState(() {});

      await completeWord();
    } else {
      guessChance--;

      guessController.clear();

      setState(() {});

      await _saveProgress();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            guessChance == 0
                ? "Tahmin hakkın bitti!"
                : "Yanlış tahmin! Kalan hak: $guessChance",
          ),
        ),
      );
    }
  }

  Future<void> guessLetter(String letter) async {
    if (letter.isEmpty) {
      return;
    }

    if (usedLetters.contains(letter)) {
      return;
    }

    bool found = false;

    for (int i = 0; i < currentWord.length; i++) {
      if (currentWord[i] == letter) {
        hiddenWord[i] = letter;

        found = true;
      }
    }

    usedLetters.add(letter);

    setState(() {});

    await _saveProgress();

    if (hiddenWord.join("") == currentWord) {
      await completeWord();

      return;
    }

    if (!found) {
      debugPrint("Yanlış harf: $letter");
    }
  }

  Future<void> completeWord() async {
    int rewardXP = 20;

    int rewardCoins = 10;

    if (widget.difficulty == "medium") {
      rewardXP = 40;

      rewardCoins = 20;
    }

    if (widget.difficulty == "hard") {
      rewardXP = 80;

      rewardCoins = 40;
    }

    final player = Provider.of<PlayerProvider>(context, listen: false);

    await player.addReward(addXp: rewardXP, addCoins: rewardCoins);

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            "🎉 Tebrikler",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Kelimeyi doğru bildin!",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 5),

              Text(
                "⭐ XP +$rewardXP",
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "🪙 Jeton +$rewardCoins",
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Divider(color: Colors.white24),

              const SizedBox(height: 10),

              const Row(
                children: [
                  Icon(Icons.school, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    "Biliyor muydun?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                currentItem?.info ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await nextWord();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                "Sonraki Kelime",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void prepareHiddenWord() {
    hiddenWord = List.generate(currentWord.length, (_) => "_");
  }

  @override
  Widget build(BuildContext context) {
    if (loadingGame) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final responsive = Responsive(context);

    final double screenWidth = responsive.width;

    final double safeHeight = responsive.safeHeight;

    final double contentWidth = screenWidth.clamp(280.0, 520.0);

    final bool isShortScreen = safeHeight < 700;

    final bool isVeryShortScreen = safeHeight < 620;

    final double cardPadding = responsive.clampWidth(0.04, min: 12, max: 18);

    final double sectionGap = isVeryShortScreen
        ? 4.0
        : isShortScreen
        ? 6.0
        : 8.0;

    final double wordBoxHeight = responsive.clampHeight(
      0.075,
      min: 56,
      max: 72,
    );

    final double inputHeight = responsive.clampHeight(0.060, min: 48, max: 56);

    final double buttonHeight = responsive.clampHeight(0.055, min: 44, max: 52);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: responsive.clampHeight(0.065, min: 50, max: 64),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Kelime Oyunu",
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.font(24),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: responsive.horizontalPadding,
                right: responsive.horizontalPadding,
                bottom: responsive.mediumGap,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  color: Colors.amber,
                                  size: responsive.font(22),
                                ),
                                SizedBox(width: responsive.smallGap),
                                Text(
                                  "Kategori",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: responsive.font(15),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: responsive.smallGap),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currentItem?.category ?? "",
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsive.font(20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(height: sectionGap),

                            const Divider(
                              color: Colors.white12,
                              thickness: 1,
                              height: 1,
                            ),

                            SizedBox(height: sectionGap),

                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.amber,
                                  size: responsive.font(22),
                                ),
                                SizedBox(width: responsive.smallGap),
                                Text(
                                  "İpucu",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: responsive.font(15),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: responsive.smallGap),

                            Text(
                              currentHint,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.font(15),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap),

                      Container(
                        width: double.infinity,
                        height: wordBoxHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.smallGap,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF172238),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hiddenWord.join(" "),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.font(30),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: sectionGap),

                      SizedBox(
                        height: inputHeight,
                        child: TextField(
                          controller: guessController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (guessChance > 0) {
                              guessWord();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Kelimeyi Tahmin Et",
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: responsive.font(15),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: responsive.mediumGap,
                              vertical: 0,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent,
                                width: 2,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.font(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: sectionGap),

                      SizedBox(
                        width: responsive.clampWidth(0.62, min: 200, max: 280),
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: guessChance > 0 ? guessWord : null,
                          icon: Icon(Icons.edit, size: responsive.font(20)),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Tahmin Et ($guessChance Hak)",
                              style: TextStyle(
                                fontSize: responsive.font(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.mediumGap,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: sectionGap),

                      WheelWidget(
                        currentWord: currentWord,
                        usedLetters: usedLetters,
                        onLetterSelected: (letter) async {
                          await guessLetter(letter);

                          if (!mounted) {
                            return;
                          }
                        },
                      ),

                      SizedBox(
                        height: responsive.clampHeight(0.08, min: 60, max: 90),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

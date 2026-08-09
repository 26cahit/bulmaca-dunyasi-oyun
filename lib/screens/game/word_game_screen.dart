// ignore_for_file: use_build_context_synchronously

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
  StreamSubscription<DatabaseEvent>? roomStateListener;
  bool gameFinished = false;
  bool myTurn = false;
  bool hadTwoPlayers = false;
  String currentTurn = "";

  int currentRound = 1;

  Map<String, dynamic> livePlayers = {};
  int multiplayerScore = 0;
  final TextEditingController guessController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _initializeGame();

    if (widget.isMultiplayer && widget.roomCode != null) {
      roomRef = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}");
      setupDisconnectHandler();
      listenPlayers();
      listenRoomState();
    }
  }

  Future<void> _initializeGame() async {
    try {
      await loadPlayerData();

      // Multiplayer olsun olmasın kelimeleri yükle
      await _loadOrCreateGame();
    } catch (e) {
      debugPrint("Oyun başlatma hatası: $e");
    } finally {
      // Ne olursa olsun loading bitsin
      if (mounted) {
        setState(() {
          loadingGame = false;
        });
      }
    }
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
    // if (widget.isMultiplayer) {
    //   return;
    // }
    final List<WordItem> sourceWords = _getDifficultyWords();

    questionOrder = List<int>.generate(sourceWords.length, (index) => index);

    questionOrder.shuffle(Random());

    shuffledWords = questionOrder.map((index) => sourceWords[index]).toList();

    currentWordIndex = 0;

    usedLetters.clear();

    guessChance = 2;

    loadCurrentWord();

    // Multiplayer ise ilk kelimeyi Firebase’e yaz
    if (widget.isMultiplayer && roomRef != null && shuffledWords.isNotEmpty) {
      final first = shuffledWords[0];
      await roomRef!.update({
        "currentWord": first.word,
        "currentHint": first.hint,
        "gameState": "playing",
      });
    }

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

  void setupDisconnectHandler() {
    if (!widget.isMultiplayer || roomRef == null || widget.playerId == null) {
      return;
    }

    final playerRef = roomRef!.child("players").child(widget.playerId!);

    playerRef.onDisconnect().update({"status": "disconnected"});
  }

  void listenPlayers() {
    roomListener = roomRef?.child("players").onValue.listen((event) async {
      if (!mounted) return;

      if (!event.snapshot.exists) return;

      final Map<dynamic, dynamic> players = Map<dynamic, dynamic>.from(
        event.snapshot.value as Map,
      );

      livePlayers = players.map(
        (key, value) =>
            MapEntry(key.toString(), Map<dynamic, dynamic>.from(value)),
      );

      // İki oyuncunun gerçekten aynı anda odada olduğunu gördük.
      if (players.length >= 2) {
        hadTwoPlayers = true;

        // Daha önce "oyuncu ayrıldı" durumu oluştuysa
        // oyuncu geri geldiğinde oyunu tekrar aktif et.
        if (gameFinished) {
          gameFinished = false;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                "✅ Oyuncu tekrar bağlandı.\nOyun devam ediyor.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {});
      }

      /*
     * ÖNEMLİ:
     *
     * currentTurn
     * myTurn
     * currentRound
     * currentWord
     * currentHint
     *
     * artık burada değiştirilmiyor.
     *
     * Bunların tamamını listenRoomState() yönetiyor.
     */

      // Gerçekten ayrılmış bir oyuncu var mı?
      String? leftPlayerId;

      for (final entry in players.entries) {
        final player = Map<dynamic, dynamic>.from(entry.value);

        final playerId = entry.key.toString();

        if (playerId != widget.playerId &&
            (player["status"] == "left" ||
                player["status"] == "disconnected")) {
          leftPlayerId = playerId;
          break;
        }
      }

      // Oyuncu gerçekten "left" olarak işaretlenmişse bildir.
      if (leftPlayerId != null && !gameFinished) {
        gameFinished = true;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
            content: Text(
              "⚠️ Diğer oyuncunun bağlantısı koptu veya oyundan ayrıldı.",
              textAlign: TextAlign.center,
            ),
          ),
        );

        return;
      }

      /*
     * İki oyuncuyu daha önce gördükten sonra
     * oyuncu sayısı tekrar 1'e düşerse bu gerçek bir
     * bağlantı kopması / odadan ayrılma olabilir.
     *
     * İlk açılışta tek oyuncu görünürse artık
     * yanlışlıkla "oyuncu ayrıldı" demeyecek.
     */
      if (hadTwoPlayers && players.length < 2 && !gameFinished) {
        gameFinished = true;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
            content: Text(
              "⚠️ Diğer oyuncunun bağlantısı koptu veya oyundan ayrıldı.",
              textAlign: TextAlign.center,
            ),
          ),
        );

        return;
      }
    });
  } // listenPlayers

  void listenRoomState() {
    roomStateListener = roomRef?.onValue.listen((event) {
      if (!mounted) return;
      if (!event.snapshot.exists) return;

      final roomData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      final firebaseTurn = roomData["currentTurn"]?.toString() ?? "";

      final firebaseWord = roomData["currentWord"]?.toString() ?? "";

      final firebaseHint = roomData["currentHint"]?.toString() ?? "";

      final firebaseRound = (roomData["round"] as num?)?.toInt() ?? 1;

      final firebaseGuessChance =
          (roomData["guessChance"] as num?)?.toInt() ?? 2;

      final firebaseUsedLetters = roomData["usedLetters"];

      final Set<String> newUsedLetters = {};

      if (firebaseUsedLetters is List) {
        for (final letter in firebaseUsedLetters) {
          newUsedLetters.add(letter.toString());
        }
      }

      currentTurn = firebaseTurn;
      myTurn = currentTurn == widget.playerId;
      currentRound = firebaseRound;
      guessChance = firebaseGuessChance;

      if (firebaseWord.isNotEmpty && firebaseWord != currentWord) {
        currentWord = firebaseWord;
        currentHint = firebaseHint;
        prepareHiddenWord();
      } else if (firebaseHint.isNotEmpty) {
        currentHint = firebaseHint;
      }

      usedLetters = newUsedLetters;

      if (currentWord.isNotEmpty) {
        prepareHiddenWord();

        for (final letter in usedLetters) {
          for (int i = 0; i < currentWord.length; i++) {
            if (currentWord[i] == letter) {
              hiddenWord[i] = letter;
            }
          }
        }
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    if (widget.isMultiplayer && roomRef != null && widget.playerId != null) {
      roomRef!.child("players").child(widget.playerId!).remove().then((
        _,
      ) async {
        final room = await roomRef!.child("players").get();

        if (!room.exists || room.children.isEmpty) {
          await roomRef!.remove();
        }
      });
    }

    roomListener?.cancel();
    roomStateListener?.cancel();
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

  Future<void> loadCurrentWord() async {
    debugPrint("STEP-1 loadCurrentWord başladı");

    if (widget.isMultiplayer && roomRef != null) {
      try {
        final room = await roomRef!.get();
        if (!room.exists) {
          debugPrint("Oda yok");
          return;
        }

        final roomData = Map<dynamic, dynamic>.from(room.value as Map);
        debugPrint(
          "STEP-2 roomData okundu → gameState: ${roomData["gameState"]}",
        );

        // Firebase'den gelen kelimeyi öncelikli kullan
        if (roomData["currentWord"] != null) {
          currentWord = roomData["currentWord"].toString();
          currentHint = roomData["currentHint"]?.toString() ?? "";
          prepareHiddenWord();
          usedLetters.clear();
          guessChance = 2;
          guessController.clear();

          if (mounted) setState(() {});
          return; // Firebase kelimesi geldi, çık
        }
      } catch (e) {
        debugPrint("loadCurrentWord multiplayer hata: $e");
      }
    }

    // Normal (tek oyunculu) yol
    if (shuffledWords.isEmpty) {
      debugPrint("shuffledWords boş");
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
    // Multiplayer'da kelimeyi Firebase belirliyor.
    // completeWord() zaten sırayı ve oyun durumunu Firebase'e yazdı.
    if (widget.isMultiplayer && roomRef != null) {
      return;
    }

    // Tek oyunculu oyun
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

    await loadCurrentWord();
    await _saveProgress();
  }

  Future<void> guessWord() async {
    if (!myTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Sıra diğer oyuncuda.", textAlign: TextAlign.center),
        ),
      );
      return;
    }
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
      if (widget.isMultiplayer && roomRef != null) {
        await roomRef!.update({"guessChance": guessChance});
      }
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
    if (!myTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Sıra diğer oyuncuda.", textAlign: TextAlign.center),
        ),
      );
      return;
    }

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

    if (widget.isMultiplayer && roomRef != null) {
      await roomRef!.update({"usedLetters": usedLetters.toList()});
    }

    if (!mounted) {
      return;
    }

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

    if (widget.isMultiplayer && roomRef != null && widget.playerId != null) {
      multiplayerScore++;

      await roomRef!.child("players").child(widget.playerId!).update({
        "score": multiplayerScore,
      });

      final snapshot = await roomRef!.child("players").get();

      if (snapshot.exists) {
        final players = Map<dynamic, dynamic>.from(snapshot.value as Map);

        final ids = players.keys.map((e) => e.toString()).toList();

        ids.sort();

        final currentIndex = ids.indexOf(widget.playerId!);

        if (currentIndex != -1 && ids.length > 1) {
          int nextIndex = currentIndex + 1;

          int round =
              ((await roomRef!.child("round").get()).value as num?)?.toInt() ??
              1;

          if (nextIndex >= ids.length) {
            nextIndex = 0;
            round++;
          }

          /*
         * Sadece burada sıra değişiyor.
         * Artık completeWord() içinde sıra değiştikten sonra
         * tekrar Sonraki Kelime butonunda sıra değiştirmiyoruz.
         */

          final nextWordIndex = currentWordIndex + 1;

          String nextWord = currentWord;
          String nextHint = currentHint;

          if (nextWordIndex < shuffledWords.length) {
            final nextItem = shuffledWords[nextWordIndex];

            nextWord = nextItem.word;
            nextHint = nextItem.hint;
          }

          await roomRef!.update({
            "currentTurn": ids[nextIndex],
            "round": round,
            "currentWord": nextWord,
            "currentHint": nextHint,
            "usedLetters": <String>[],
            "guessChance": 2,
            "gameState": "playing",
          });

          await roomRef!.child("players").child(widget.playerId!).update({
            "status": "waiting",
          });

          await roomRef!.child("players").child(ids[nextIndex]).update({
            "status": "playing",
          });
        }
      }
    }

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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                "Devam Et",
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
    // Güvenli kopya
    final Map<dynamic, dynamic> onlinePlayers =
        Map<dynamic, dynamic>.from(livePlayers)..removeWhere((key, value) {
          final player = Map<dynamic, dynamic>.from(value);
          return player["status"] == "left";
        });

    if (loadingGame) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final responsive = Responsive(context);
    final double screenWidth = responsive.width;
    final double contentWidth = screenWidth.clamp(280.0, 520.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Kelime Oyunu",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === Canlı Puan Durumu ===
                  if (widget.isMultiplayer)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🏆 Canlı Puan Durumu",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "🎮 Tur : $currentRound",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            myTurn
                                ? "🟢 Sıra Sende"
                                : "🟡 Diğer Oyuncu Oynuyor",
                            style: TextStyle(
                              color: myTurn ? Colors.green : Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          ...onlinePlayers.entries.map((entry) {
                            final data = Map<dynamic, dynamic>.from(
                              entry.value,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      data["name"] ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${data["score"] ?? 0} Puan",
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  // === Kategori + İpucu ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kategori",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentItem?.category ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white12),
                        const Text(
                          "İpucu",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentHint,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === Gizli Kelime ===
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF172238),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Center(
                      child: Text(
                        hiddenWord.join(" "),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === Tahmin Kutusu ===
                  TextField(
                    controller: guessController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (myTurn && guessChance > 0) guessWord();
                    },
                    decoration: InputDecoration(
                      hintText: "Kelimeyi Tahmin Et",
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // === Tahmin Butonu ===
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: guessWord,
                      icon: const Icon(Icons.edit),
                      label: Text("Tahmin Et ($guessChance Hak)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === Harf Çarkı ===
                  WheelWidget(
                    currentWord: currentWord,
                    usedLetters: usedLetters,
                    onLetterSelected: (letter) async {
                      if (!myTurn) return;
                      await guessLetter(letter);
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

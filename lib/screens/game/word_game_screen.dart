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
  // DÜZELTME 1: Tek listener kullanıyoruz, çift listener bug'ı gitti
  StreamSubscription<DatabaseEvent>? _roomSub;
  bool gameFinished = false;
  bool myTurn = false;
  bool hadTwoPlayers = false;
  String currentTurn = "";
  int currentRound = 1;
  Map<String, dynamic> livePlayers = {};
  int multiplayerScore = 0;
  // DÜZELTME 2: Çark kontrolü için
  bool hasSpunWheel = false;
  List<String> playerOrder = []; // DÜZELTME 3: Sabit sıra listesi
  final TextEditingController guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGame();
    if (widget.isMultiplayer && widget.roomCode != null) {
      roomRef = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}");
      _setupPresence();
      _listenRoom(); // Tek listener
    }
  }

  Future<void> _initializeGame() async {
    try {
      await loadPlayerData();
      await _loadOrCreateGame();
    } catch (e) {
      debugPrint("Oyun başlatma hatası: $e");
    } finally {
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
    final List<WordItem> sourceWords = _getDifficultyWords();
    questionOrder = List<int>.generate(sourceWords.length, (index) => index);
    questionOrder.shuffle(Random());
    shuffledWords = questionOrder.map((index) => sourceWords[index]).toList();
    currentWordIndex = 0;
    usedLetters.clear();
    guessChance = 2;
    loadCurrentWord();
    if (widget.isMultiplayer && roomRef != null && shuffledWords.isNotEmpty) {
      final first = shuffledWords[0];
      // İlk kurulumda playerOrder yoksa oluştur
      await roomRef!.update({
        "currentWord": first.word,
        "currentHint": first.hint,
        "gameState": "playing",
        "guessChance": 2,
        "usedLetters": [],
      });
    }
    await _saveProgress();
  }

  void _loadSavedWord() {
    if (shuffledWords.isEmpty) return;
    currentItem = shuffledWords[currentWordIndex];
    currentWord = currentItem!.word;
    currentHint = currentItem!.hint;
    prepareHiddenWord();
    for (final String letter in usedLetters) {
      for (int i = 0; i < currentWord.length; i++) {
        if (currentWord[i] == letter) hiddenWord[i] = letter;
      }
    }
    guessController.clear();
  }

  Future<void> _saveProgress() async {
    if (shuffledWords.isEmpty) return;
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

  // DÜZELTME: Presence sistemi iyileştirildi
  void _setupPresence() {
    if (!widget.isMultiplayer || roomRef == null || widget.playerId == null)
      // ignore: curly_braces_in_flow_control_structures
      return;
    final playerRef = roomRef!.child("players").child(widget.playerId!);
    final connectedRef = FirebaseDatabase.instance.ref(".info/connected");
    connectedRef.onValue.listen((event) {
      bool connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        playerRef.update({"online": true, "status": "playing"});
        playerRef.onDisconnect().update({
          "online": false,
          "status": "disconnected",
        });
      }
    });
  }

  void _showInfo(String msg, {Color color = Colors.blueGrey}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: color,
        content: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  // DÜZELTME: TEK LİSTENER - Hem players hem room state burada
  void _listenRoom() {
    _roomSub = roomRef?.onValue.listen((event) async {
      if (!mounted) return;
      if (!event.snapshot.exists) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final roomData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final playersRaw = roomData["players"];
      if (playersRaw == null) return;
      final Map<dynamic, dynamic> players = Map<dynamic, dynamic>.from(
        playersRaw as Map,
      );

      final firebaseTurn = roomData["currentTurn"]?.toString() ?? currentTurn;
      final firebaseWord = roomData["currentWord"]?.toString() ?? "";
      final firebaseHint = roomData["currentHint"]?.toString() ?? "";
      final firebaseRound = (roomData["round"] as num?)?.toInt() ?? 1;
      final firebaseGuessChance =
          (roomData["guessChance"] as num?)?.toInt() ?? 2;
      final firebaseUsedLetters = roomData["usedLetters"];
      final lastAction = roomData["lastAction"] != null
          ? Map<String, dynamic>.from(roomData["lastAction"])
          : null;
      final firebaseOrder = roomData["playerOrder"];

      // Order listesini güncelle
      if (firebaseOrder is List) {
        playerOrder = firebaseOrder.map((e) => e.toString()).toList();
      }

      // İki oyuncuyu gördük mü?
      if (players.length >= 2) {
        if (!hadTwoPlayers) {
          hadTwoPlayers = true;
          // İlk kez playerOrder oluştur - sadece host yapsın
          if (playerOrder.isEmpty) {
            final isHostEntry = players.entries.where((e) {
              final v = Map<dynamic, dynamic>.from(e.value);
              return v["isHost"] == true;
            });
            if (isHostEntry.isNotEmpty &&
                isHostEntry.first.key.toString() == widget.playerId) {
              final order = players.keys.map((e) => e.toString()).toList();
              await roomRef!.update({"playerOrder": order});
              playerOrder = order;
            }
          }
        }
        if (gameFinished) {
          setState(() => gameFinished = false);
          _showInfo(
            "✅ Oyuncu tekrar bağlandı. Oyun devam ediyor.",
            color: Colors.green,
          );
        }
      }

      // Ayrılan oyuncu kontrolü
      String? leftPlayerId;
      for (final entry in players.entries) {
        final p = Map<dynamic, dynamic>.from(entry.value);
        final pid = entry.key.toString();
        if (pid != widget.playerId &&
            (p["status"] == "left" ||
                p["status"] == "disconnected" && p["online"] == false)) {
          leftPlayerId = pid;
          break;
        }
      }

      // Bildirimler - lastAction ile
      if (lastAction != null && lastAction["playerId"] != widget.playerId) {
        if (lastAction["type"] == "wheel_spun") {
          _showInfo(
            "🎡 ${lastAction["playerName"]} çarkı çevirdi: ${lastAction["value"]}",
          );
        } else if (lastAction["type"] == "turn_passed") {
          String nextName = "diğer oyuncuya";
          if (players.containsKey(lastAction["nextPlayerId"])) {
            nextName =
                Map<dynamic, dynamic>.from(
                  players[lastAction["nextPlayerId"]],
                )["name"] ??
                nextName;
          }
          _showInfo("➡️ Sıra $nextName geçti", color: Colors.orange);
        }
      }

      if (leftPlayerId != null && !gameFinished) {
        setState(() => gameFinished = true);
        _showInfo(
          "⚠ Diğer oyuncunun bağlantısı koptu veya ayrıldı.",
          color: Colors.orange,
        );
      } else if (hadTwoPlayers && players.length < 2 && !gameFinished) {
        setState(() => gameFinished = true);
        _showInfo(
          "⚠ Diğer oyuncunun bağlantısı koptu veya ayrıldı.",
          color: Colors.orange,
        );
      }

      // State güncelleme
      Set<String> newUsedLetters = {};
      if (firebaseUsedLetters is List) {
        for (final letter in firebaseUsedLetters) {
          newUsedLetters.add(letter.toString());
        }
      }

      if (mounted) {
        setState(() {
          livePlayers = players.map(
            (key, value) =>
                MapEntry(key.toString(), Map<dynamic, dynamic>.from(value)),
          );
          currentTurn = firebaseTurn;
          myTurn = currentTurn == widget.playerId;
          currentRound = firebaseRound;
          guessChance = firebaseGuessChance;
          usedLetters = newUsedLetters;

          if (firebaseWord.isNotEmpty && firebaseWord != currentWord) {
            currentWord = firebaseWord;
            currentHint = firebaseHint;
            prepareHiddenWord();
            hasSpunWheel = false; // Yeni kelimede çark sıfırlanır
          } else if (firebaseHint.isNotEmpty) {
            currentHint = firebaseHint;
          }

          if (currentWord.isNotEmpty) {
            prepareHiddenWord();
            for (final letter in usedLetters) {
              for (int i = 0; i < currentWord.length; i++) {
                if (currentWord[i] == letter) hiddenWord[i] = letter;
              }
            }
          }
        });
      }
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
    _roomSub?.cancel();
    guessController.dispose();
    super.dispose();
  }

  Future<void> loadPlayerData() async {
    xp = await PlayerService.getXP();
    coins = await PlayerService.getCoins();
    level = await PlayerService.getLevel();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadCurrentWord() async {
    if (widget.isMultiplayer && roomRef != null) {
      try {
        final room = await roomRef!.get();
        if (!room.exists) return;
        final roomData = Map<dynamic, dynamic>.from(room.value as Map);
        if (roomData["currentWord"] != null) {
          currentWord = roomData["currentWord"].toString();
          currentHint = roomData["currentHint"]?.toString() ?? "";
          prepareHiddenWord();
          usedLetters.clear();
          guessChance = 2;
          guessController.clear();
          if (mounted) setState(() {});
          return;
        }
      } catch (e) {
        debugPrint("loadCurrentWord multiplayer hata: $e");
      }
    }
    if (shuffledWords.isEmpty) return;
    currentItem = shuffledWords[currentWordIndex];
    currentWord = currentItem!.word;
    currentHint = currentItem!.hint;
    prepareHiddenWord();
    usedLetters.clear();
    guessChance = 2;
    guessController.clear();
    if (mounted) setState(() {});
  }

  Future<void> nextWord() async {
    if (widget.isMultiplayer && roomRef != null) return;
    if (shuffledWords.isEmpty) return;
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
    if (widget.isMultiplayer && !myTurn) {
      _showInfo("Sıra diğer oyuncuda.", color: Colors.orange);
      return;
    }
    if (guessChance == 0) return;
    final String guess = guessController.text.trim();
    if (guess.isEmpty) return;
    if (guess.toUpperCase() == currentWord.trim().toUpperCase()) {
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
      if (!mounted) return;
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
    if (widget.isMultiplayer && !myTurn) {
      _showInfo("Sıra diğer oyuncuda.", color: Colors.orange);
      return;
    }
    // Çark çevirmeden harf açamasın - Multiplayer için
    if (widget.isMultiplayer && !hasSpunWheel) {
      _showInfo("Önce çarkı çevirmelisin!", color: Colors.orange);
      return;
    }
    if (letter.isEmpty) return;
    if (usedLetters.contains(letter)) return;
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
    if (!mounted) return;
    setState(() {});
    await _saveProgress();
    if (hiddenWord.join("") == currentWord) {
      await completeWord();
      return;
    }
    if (!found && widget.isMultiplayer) {
      // Yanlış harf = sıra geçsin
      await _passTurn();
    }
  }

  // Çark çevirme fonksiyonu - WheelWidget'tan çağrılacak
  Future<void> onWheelSpun(String resultValue) async {
    if (!myTurn) {
      _showInfo("Sıra sizde değil!", color: Colors.orange);
      return;
    }
    if (hasSpunWheel) return;
    setState(() => hasSpunWheel = true);
    await roomRef!.update({
      "lastAction": {
        "type": "wheel_spun",
        "playerId": widget.playerId,
        "playerName": context.read<PlayerProvider>().playerName,
        "value": resultValue,
        "timestamp": ServerValue.timestamp,
      },
      "gameState": "answering",
    });
    _showInfo("Çark: $resultValue - Şimdi harf seç!", color: Colors.green);
  }

  Future<void> _passTurn() async {
    if (roomRef == null) return;
    try {
      final roomSnap = await roomRef!.get();
      if (!roomSnap.exists) return;
      final roomData = Map<dynamic, dynamic>.from(roomSnap.value as Map);
      List<String> order = [];
      if (roomData["playerOrder"] is List) {
        order = (roomData["playerOrder"] as List)
            .map((e) => e.toString())
            .toList();
      } else {
        final playersSnap = await roomRef!.child("players").get();
        if (playersSnap.exists) {
          order = (Map<dynamic, dynamic>.from(
            playersSnap.value as Map,
          )).keys.map((e) => e.toString()).toList();
          await roomRef!.update({"playerOrder": order});
        }
      }
      if (order.isEmpty) return;
      int currentIndex = order.indexOf(widget.playerId ?? "");
      if (currentIndex == -1) currentIndex = order.indexOf(currentTurn);
      if (currentIndex == -1) currentIndex = 0;
      int nextIndex = (currentIndex + 1) % order.length;
      await roomRef!.update({
        "currentTurn": order[nextIndex],
        "round": currentRound + (nextIndex == 0 ? 1 : 0),
        "lastAction": {
          "type": "turn_passed",
          "playerId": widget.playerId,
          "nextPlayerId": order[nextIndex],
          "timestamp": ServerValue.timestamp,
        },
        "gameState": "waiting_for_spin",
      });
      setState(() => hasSpunWheel = false);
    } catch (e) {
      debugPrint("passTurn hata: $e");
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

      // DÜZELTME: Artık ids.sort() yok, sabit playerOrder kullanılıyor
      final roomSnap = await roomRef!.get();
      List<String> ids = playerOrder;
      if (roomSnap.exists) {
        final data = Map<dynamic, dynamic>.from(roomSnap.value as Map);
        if (data["playerOrder"] is List) {
          ids = (data["playerOrder"] as List).map((e) => e.toString()).toList();
        } else {
          final playersSnap = await roomRef!.child("players").get();
          if (playersSnap.exists) {
            ids = Map<dynamic, dynamic>.from(
              playersSnap.value as Map,
            ).keys.map((e) => e.toString()).toList();
          }
        }
      }

      final currentIndex = ids.indexOf(widget.playerId!);
      if (currentIndex != -1 && ids.length > 1) {
        int nextIndex = currentIndex + 1;
        int round = currentRound;
        if (nextIndex >= ids.length) {
          nextIndex = 0;
          round++;
        }
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
          "lastAction": {
            "type": "word_completed",
            "playerId": widget.playerId,
            "playerName": context.read<PlayerProvider>().playerName,
            "word": currentWord,
            "timestamp": ServerValue.timestamp,
          },
        });
        await roomRef!.child("players").child(widget.playerId!).update({
          "status": "waiting",
        });
        await roomRef!.child("players").child(ids[nextIndex]).update({
          "status": "playing",
        });
      }
    }

    if (!mounted) return;
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
              onPressed: () => Navigator.pop(dialogContext),
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
                                ? "🟢 Sıra Sende ${hasSpunWheel ? '(Harf Seç)' : '(Çarkı Çevir)'}"
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
                            final isTurn = entry.key.toString() == currentTurn;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${isTurn ? '👉 ' : ''}${data["name"] ?? ""} ${data["online"] == false ? '(Bağlantı koptu)' : ''}",
                                      style: TextStyle(
                                        color: isTurn
                                            ? Colors.amber
                                            : Colors.white,
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
                  TextField(
                    controller: guessController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!widget.isMultiplayer || (myTurn && guessChance > 0))
                        // ignore: curly_braces_in_flow_control_structures
                        guessWord();
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
                  WheelWidget(
                    currentWord: currentWord,
                    usedLetters: usedLetters,
                    onLetterSelected: (letter) async {
                      if (widget.isMultiplayer && !myTurn) return;
                      await guessLetter(letter);
                    },
                    // Eğer WheelWidget'ında onSpinEnd varsa burayı kullan
                    // onSpinEnd: onWheelSpun,
                    // isEnabled: !widget.isMultiplayer || (myTurn && !hasSpunWheel),
                  ),
                  // Çark çevir butonu - WheelWidget spin'i kendisi yapmıyorsa
                  if (widget.isMultiplayer)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: !myTurn || hasSpunWheel
                              ? null
                              : () => onWheelSpun(
                                  "${Random().nextInt(10) * 100} Puan",
                                ),
                          icon: const Icon(Icons.casino),
                          label: Text(
                            hasSpunWheel ? "Harf Seçmelisin" : "ÇARKI ÇEVİR",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasSpunWheel
                                ? Colors.grey
                                : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
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

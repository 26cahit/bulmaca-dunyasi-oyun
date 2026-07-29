import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import 'room_lobby_screen.dart';

class QuickMatchScreen extends StatefulWidget {
  final String game;

  const QuickMatchScreen({super.key, required this.game});

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen> {
  final DatabaseReference quickMatchRef = FirebaseDatabase.instance.ref(
    'quickMatch',
  );

  final DatabaseReference roomsRef = FirebaseDatabase.instance.ref('rooms');

  StreamSubscription<DatabaseEvent>? quickMatchSubscription;

  bool isSearching = false;
  bool matchFound = false;

  String statusText = 'Rakip aramaya hazır';
  String opponentName = '';
  String opponentAvatar = '';
  int countdown = 3;
  bool showMatchFound = false;
  bool myTurn = false;
  String? myQueueId;

  Future<void> startQuickMatch() async {
    if (isSearching) {
      return;
    }

    final playerProvider = context.read<PlayerProvider>();
    final String playerName = playerProvider.playerName.trim();

    setState(() {
      isSearching = true;
      matchFound = false;
      statusText = '${widget.game} için rakip aranıyor...';
    });

    try {
      final DataSnapshot queueSnapshot = await quickMatchRef.get();

      String? waitingPlayerId;

      Map<dynamic, dynamic>? waitingPlayerData;

      if (queueSnapshot.exists && queueSnapshot.value is Map) {
        final Map<dynamic, dynamic> queueData = Map<dynamic, dynamic>.from(
          queueSnapshot.value as Map,
        );

        for (final entry in queueData.entries) {
          if (entry.value is! Map) {
            continue;
          }

          final Map<dynamic, dynamic> playerData = Map<dynamic, dynamic>.from(
            entry.value as Map,
          );

          final String status = playerData['status']?.toString() ?? '';

          final String waitingGame = playerData['game']?.toString() ?? '';

          if (status == 'waiting' && waitingGame == widget.game) {
            waitingPlayerId = entry.key.toString();

            waitingPlayerData = playerData;

            break;
          }
        }
      }

      if (waitingPlayerId != null && waitingPlayerData != null) {
        await createMatch(waitingPlayerId, waitingPlayerData, playerName);
      } else {
        await addToQueue(playerName);
      }
    } catch (e, stackTrace) {
      debugPrint('HIZLI ESLESME HATASI: $e');

      debugPrint('HATA DETAYI: $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        isSearching = false;

        statusText = 'Eşleşme başlatılamadı';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hızlı eşleşme hatası: $e',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addToQueue(String playerName) async {
    final playerProvider = context.read<PlayerProvider>();
    final DatabaseReference newQueueRef = quickMatchRef.push();

    myQueueId = newQueueRef.key;

    await newQueueRef.set({
      'name': playerName,
      'avatar': playerProvider.avatar,
      'game': widget.game,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
    });

    listenMyQueue();
  }

  void listenMyQueue() {
    final String? queueId = myQueueId;

    if (queueId == null) {
      return;
    }

    quickMatchSubscription?.cancel();

    quickMatchSubscription = quickMatchRef.child(queueId).onValue.listen((
      DatabaseEvent event,
    ) async {
      if (!event.snapshot.exists) {
        return;
      }

      final dynamic value = event.snapshot.value;

      if (value is! Map) {
        return;
      }

      final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);

      final String status = data['status']?.toString() ?? '';

      final String roomCode = data['roomCode']?.toString() ?? '';
      final String playerId = data['playerId']?.toString() ?? '';
      if (status == 'matched' && roomCode.isNotEmpty && !matchFound) {
        matchFound = true;

        if (mounted) {
          setState(() {
            statusText = 'Rakip bulundu!';
            opponentName = data['opponentName'] ?? 'Rakip';
            opponentAvatar = data['opponentAvatar'] ?? '';
            myTurn = data['firstTurn'] == true;
          });
        }

        await showMatchFoundScreen(roomCode, playerId);
      }
    });
  }

  Future<void> createMatch(
    String waitingPlayerId,
    Map<dynamic, dynamic> waitingPlayerData,
    String playerName,
  ) async {
    final playerProvider = context.read<PlayerProvider>();
    final String roomCode = generateRoomCode();

    final String waitingPlayerName =
        waitingPlayerData['name']?.toString() ?? 'Oyuncu';

    final String waitingGame =
        waitingPlayerData['game']?.toString() ?? widget.game;

    final DatabaseReference roomRef = roomsRef.child(roomCode);

    final DatabaseReference hostPlayerRef = roomRef.child('players').push();

    final DatabaseReference guestPlayerRef = roomRef.child('players').push();

    await roomRef.set({
      'createdAt': ServerValue.timestamp,
      'game': waitingGame,
      'maxPlayers': 2,
      'roomCode': roomCode,
      'status': 'waiting',
      'players': {
        hostPlayerRef.key: {
          'name': waitingPlayerName,
          'avatar': waitingPlayerData['avatar'],
          'joinedAt': ServerValue.timestamp,
          'score': 0,
          'isHost': true,
        },
        guestPlayerRef.key: {
          'name': playerName,
          'avatar': playerProvider.avatar,
          'joinedAt': ServerValue.timestamp,
          'score': 0,
          'isHost': false,
        },
      },
    });

    final bool hostStarts = DateTime.now().millisecondsSinceEpoch.isEven;

    await roomRef.update({'firstTurn': hostStarts});

    await quickMatchRef.child(waitingPlayerId).update({
      'status': 'matched',
      'roomCode': roomCode,
      'playerId': hostPlayerRef.key,
      'opponentName': playerName,
      'opponentAvatar': playerProvider.avatar,
      'firstTurn': hostStarts,
    });

    await roomRef.update({'status': 'ready'});

    if (!mounted) {
      return;
    }

    setState(() {
      statusText = 'Rakip bulundu!';
      opponentName = waitingPlayerName;
      opponentAvatar = waitingPlayerData['avatar']?.toString() ?? '';
      myTurn = !hostStarts;
    });

    matchFound = true;
    await showMatchFoundScreen(roomCode, guestPlayerRef.key!);
  }

  Future<void> showMatchFoundScreen(String roomCode, String playerId) async {
    if (!mounted) return;

    setState(() {
      showMatchFound = true;
      countdown = 3;
    });

    while (countdown > 1) {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        countdown--;
      });
    }

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    openLobby(roomCode, playerId);
  }

  String generateRoomCode() {
    const String characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final int timestamp = DateTime.now().microsecondsSinceEpoch;

    String code = '';

    int value = timestamp;

    for (int i = 0; i < 6; i++) {
      final int index = value % characters.length;

      code += characters[index];

      value = value ~/ characters.length;
    }

    return code;
  }

  void openLobby(String roomCode, String playerId) {
    if (!mounted) {
      return;
    }

    quickMatchSubscription?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            RoomLobbyScreen(roomCode: roomCode, playerId: playerId),
      ),
    );
  }

  Future<void> cancelQuickMatch() async {
    quickMatchSubscription?.cancel();

    final String? queueId = myQueueId;

    if (queueId != null) {
      await quickMatchRef.child(queueId).remove();
    }

    myQueueId = null;

    if (!mounted) {
      return;
    }

    setState(() {
      isSearching = false;

      matchFound = false;

      statusText = 'Rakip aramaya hazır';
    });
  }

  @override
  void dispose() {
    quickMatchSubscription?.cancel();

    final String? queueId = myQueueId;

    if (queueId != null && !matchFound) {
      quickMatchRef.child(queueId).remove();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hızlı Eşleşme',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (showMatchFound)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sports_esports,
                        color: Colors.amber,
                        size: 90,
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "RAKİP BULUNDU",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 35),

                      Text(
                        opponentName,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        myTurn ? "🟢 İlk Hamle Senin" : "🟡 Rakip Başlıyor",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 35),

                      Text(
                        "$countdown",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Oyuna Geçiliyor...",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      isSearching
                          ? const SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                                strokeWidth: 7,
                              ),
                            )
                          : const Icon(
                              Icons.groups,
                              color: Colors.amber,
                              size: 80,
                            ),
                      const SizedBox(height: 30),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.game} oynayan bir rakiple eşleşirsin.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton(
                    onPressed: isSearching ? cancelQuickMatch : startQuickMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSearching ? Colors.red : Colors.amber,
                      foregroundColor: isSearching
                          ? Colors.white
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isSearching ? 'ARAMAYI İPTAL ET' : 'RAKİP BUL',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

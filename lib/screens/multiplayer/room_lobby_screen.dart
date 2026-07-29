import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

import '../game/word_game_screen.dart';
import '../intelligence/intelligence_home_screen.dart';
import '../knowledge/knowledge_home_screen.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomCode;
  final String playerId;

  const RoomLobbyScreen({
    super.key,
    required this.roomCode,
    required this.playerId,
  });

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  late final DatabaseReference roomRef;
  StreamSubscription<DatabaseEvent>? roomSubscription;

  bool gameOpened = false;
  bool iAmReady = false;
  @override
  void initState() {
    super.initState();

    roomRef = FirebaseDatabase.instance.ref('rooms/${widget.roomCode}');

    listenRoom();
  }

  void listenRoom() {
    roomSubscription = roomRef.onValue.listen((event) async {
      if (!mounted) {
        return;
      }

      if (!event.snapshot.exists) {
        return;
      }

      final Map<dynamic, dynamic> roomData = Map<dynamic, dynamic>.from(
        event.snapshot.value as Map,
      );

      final String game = roomData['game']?.toString() ?? '';
      final Map<dynamic, dynamic> players = roomData['players'] == null
          ? {}
          : Map<dynamic, dynamic>.from(roomData['players'] as Map);
      if (!gameOpened && players.length == 2) {
        bool everyoneReady = true;

        for (final player in players.values) {
          final data = Map<dynamic, dynamic>.from(player);

          if (data["ready"] != true) {
            everyoneReady = false;
            break;
          }
        }

        if (everyoneReady) {
          gameOpened = true;

          await roomRef.update({"status": "ready"});

          await roomSubscription?.cancel();

          if (!mounted) return;

          FocusManager.instance.primaryFocus?.unfocus();

          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          openGame(game);
        }
      }
    });
  }

  Future<void> setReady() async {
    await roomRef.child("players").child(widget.playerId).update({
      "ready": true,
    });

    if (!mounted) return;

    setState(() {
      iAmReady = true;
    });
  }

  @override
  void dispose() {
    roomSubscription?.cancel();

    super.dispose();
  }

  void openGame(String game) {
    Widget gameScreen;

    switch (game) {
      case 'Kelime Dünyası':
        gameScreen = WordGameScreen(
          difficulty: 'easy',
          isMultiplayer: true,
          roomCode: widget.roomCode,
          playerId: widget.playerId,
        );
        break;

      case 'Zeka Dünyası':
        gameScreen = const IntelligenceHomeScreen();
        break;

      case 'Bilgi Dünyası':
        gameScreen = const KnowledgeHomeScreen();
        break;

      default:
        gameOpened = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Oyun türü bulunamadı: $game',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
      (route) => false,
    );
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
          'Bekleme Odası',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: roomRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Oda bilgileri alınamadı.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final DataSnapshot? roomSnapshot = snapshot.data?.snapshot;

            if (roomSnapshot == null || !roomSnapshot.exists) {
              return const Center(
                child: Text(
                  'Oda bulunamadı.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            final Map<dynamic, dynamic> roomData = Map<dynamic, dynamic>.from(
              roomSnapshot.value as Map,
            );

            final String game = roomData['game']?.toString() ?? '';

            final int maxPlayers =
                (roomData['maxPlayers'] as num?)?.toInt() ?? 2;

            final String status = roomData['status']?.toString() ?? 'waiting';

            final Map<dynamic, dynamic> players = roomData['players'] == null
                ? {}
                : Map<dynamic, dynamic>.from(roomData['players'] as Map);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.groups, color: Colors.amber, size: 58),
                        const SizedBox(height: 14),
                        const Text(
                          'Oda Kodu',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: widget.roomCode),
                            );

                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Oda kodu kopyalandı.',
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Color(0xFF1E293B),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.roomCode,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.copy,
                                  color: Colors.amber,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kopyalamak için oda koduna dokun',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          game,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Oyuncular',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${players.length} / $maxPlayers',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ...players.entries.map((entry) {
                          final Map<dynamic, dynamic> playerData =
                              Map<dynamic, dynamic>.from(entry.value as Map);

                          final String playerName =
                              playerData['name']?.toString() ?? 'Oyuncu';

                          final bool isHost = playerData['isHost'] == true;
                          final bool ready = playerData["ready"] == true;
                          final String avatar =
                              playerData['avatar']?.toString() ?? '🙂';
                          final bool isCustomAvatar = avatar.startsWith('http');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: isHost
                                      ? Colors.amber
                                      : Colors.white24,
                                  child: isCustomAvatar
                                      ? ClipOval(
                                          child: Image.network(
                                            avatar,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 30,
                                                  );
                                                },
                                          ),
                                        )
                                      : Text(
                                          avatar,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    playerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (isHost)
                                      const Text(
                                        "ODA SAHİBİ",
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),

                                    const SizedBox(height: 6),

                                    Text(
                                      ready ? "🟢 HAZIR" : "🟡 BEKLİYOR",
                                      style: TextStyle(
                                        color: ready
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.amber,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          status == 'waiting'
                              ? 'Oyuncular bekleniyor...'
                              : 'Oyun açılıyor...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: iAmReady ? null : setReady,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        iAmReady ? "HAZIRSIN" : "HAZIRIM",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class GamePlaceholderScreen extends StatelessWidget {
  final String gameName;
  final IconData icon;

  const GamePlaceholderScreen({
    super.key,
    required this.gameName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          gameName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              Text(
                gameName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Çok oyunculu oyun ekranı hazırlanıyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

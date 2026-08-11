// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

    // Oyuncu bağlantısı kopunca kendini sil
    roomRef.child('players').child(widget.playerId).onDisconnect().remove();

    // Host ise bağlantı kopunca tüm odayı sil
    _setupHostOnDisconnect();
  }

  Future<void> _setupHostOnDisconnect() async {
    try {
      final snap = await roomRef.child('players').child(widget.playerId).get();
      if (!snap.exists) return;

      final data = Map<dynamic, dynamic>.from(snap.value as Map);
      if (data['isHost'] == true) {
        // Host kopunca tüm odayı sil
        roomRef.onDisconnect().remove();
      }
    } catch (e) {
      debugPrint("Host onDisconnect ayarlanamadı: $e");
    }
  }

  Future<void> setReady() async {
    if (iAmReady) return;

    await roomRef.child("players").child(widget.playerId).update({
      "ready": true,
    });

    if (!mounted) return;

    setState(() {
      iAmReady = true;
    });
  }

  Future<void> leaveRoom() async {
    try {
      final room = await roomRef.get();
      if (!room.exists) return;

      final roomData = Map<dynamic, dynamic>.from(room.value as Map);
      final players = roomData["players"] == null
          ? {}
          : Map<dynamic, dynamic>.from(roomData["players"]);

      final myData = Map<dynamic, dynamic>.from(players[widget.playerId] ?? {});

      if (myData["isHost"] == true) {
        // Host çıkıyorsa odayı tamamen sil
        await roomRef.remove();
      } else {
        // Misafir çıkıyorsa sadece kendini sil
        await roomRef.child("players").child(widget.playerId).remove();

        // Oda boş kaldıysa sil
        final check = await roomRef.child("players").get();
        if (!check.exists || check.children.isEmpty) {
          await roomRef.remove();
        }
      }
    } catch (e) {
      debugPrint("leaveRoom hata: $e");
    }
  }

  @override
  void dispose() {
    roomSubscription?.cancel();

    // Oyun açılırken lobi kapanıyor.
    // Bu durumda oyuncuyu odadan silme.
    if (!gameOpened) {
      leaveRoom();
    }

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

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await leaveRoom();
        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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

              if (status == "starting" && !gameOpened) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || gameOpened) return;
                  gameOpened = true;
                  openGame(game);
                });
              }

              final Map<dynamic, dynamic> players = roomData['players'] == null
                  ? {}
                  : Map<dynamic, dynamic>.from(roomData['players'] as Map);

              // Host herkes hazırsa oyunu başlatsın
              // === OYUN BAŞLATMA KONTROLÜ ===
              if (status == "starting" && !gameOpened) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || gameOpened) return;
                  gameOpened = true;
                  debugPrint("OYUN AÇILIYOR → $game");
                  openGame(game);
                });
              }

              // Host herkes hazırsa status'ü starting yapsın
              if (!gameOpened && status == "waiting") {
                bool everyoneReady = true;
                for (final player in players.values) {
                  final data = Map<dynamic, dynamic>.from(player);
                  if (data["ready"] != true) {
                    everyoneReady = false;
                    break;
                  }
                }

                final myData = Map<dynamic, dynamic>.from(
                  players[widget.playerId] ?? {},
                );

                if (myData["isHost"] == true &&
                    players.length >= maxPlayers &&
                    everyoneReady) {
                  debugPrint("HOST → herkes hazır, status=starting yazılıyor");
                  roomRef
                      .update({
                        "status": "starting",
                        "round": 1,
                        "currentTurn": players.keys.first.toString(),
                        "gameState": "loading",
                      })
                      .then((_) {
                        debugPrint("HOST → status=starting başarıyla yazıldı");
                      })
                      .catchError((e) {
                        debugPrint("HOST status yazma hatası: $e");
                      });
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // === ODA BİLGİSİ KARTI ===
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.groups,
                            color: Colors.amber,
                            size: 58,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            roomData["roomName"] ?? "Oda",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            game,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$maxPlayers Kişilik Oda",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // === OYUNCULAR LİSTESİ ===
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
                            final bool isCustomAvatar = avatar.startsWith(
                              'http',
                            );

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
                                            style: const TextStyle(
                                              fontSize: 28,
                                            ),
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

                    // === DURUM YAZISI ===
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
                                : status == 'starting'
                                ? 'Oyun açılıyor...'
                                : 'Hazırlanıyor...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // === HAZIRIM BUTONU ===
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
      ),
    );
  }
}

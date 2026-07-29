import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import 'room_lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final Random random = Random();
  final DatabaseReference roomsRef = FirebaseDatabase.instance.ref('rooms');
  late String roomCode;

  String selectedGame = 'Kelime Dünyası';

  int selectedPlayerCount = 2;

  final List<String> games = [
    'Kelime Dünyası',
    'Zeka Dünyası',
    'Bilgi Dünyası',
  ];

  @override
  void initState() {
    super.initState();

    createRoomCode();
  }

  void createRoomCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    roomCode = List.generate(
      6,
      (index) => characters[random.nextInt(characters.length)],
    ).join();
  }

  Future<void> startGame() async {
    try {
      final player = context.read<PlayerProvider>();

      final String playerName = player.playerName.trim();

      if (playerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Önce profilini oluştur.',
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }
      final DatabaseReference roomRef = roomsRef.child(roomCode);

      await roomRef.set({
        'roomCode': roomCode,
        'game': selectedGame,
        'maxPlayers': selectedPlayerCount,
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'players': {
          'player1': {
            'name': playerName,
            'avatar': player.avatar,
            'score': 0,
            'isHost': true,
            'joinedAt': ServerValue.timestamp,
          },
        },
      });

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RoomLobbyScreen(roomCode: roomCode, playerId: "player1"),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('FIREBASE ODA HATASI: $error');

      debugPrint('HATA DETAYI: $stackTrace');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oda oluşturulamadı: $error',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Oda Oluştur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                        const Icon(
                          Icons.meeting_room,
                          color: Colors.amber,
                          size: 52,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Oda Kodun',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            roomCode,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Arkadaşların bu kod ile odana katılabilir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Oyun Seç',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedGame,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: games.map((game) {
                            return DropdownMenuItem<String>(
                              value: game,
                              child: Text(game),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedGame = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Oyuncu Sayısı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            for (final playerCount in [2, 3, 4])
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: playerCount == 4 ? 0 : 8,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        selectedPlayerCount = playerCount;
                                      });
                                    },
                                    child: Container(
                                      height: 62,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            selectedPlayerCount == playerCount
                                            ? Colors.amber
                                            : const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              selectedPlayerCount == playerCount
                                              ? Colors.amber
                                              : Colors.white24,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        '$playerCount',
                                        style: TextStyle(
                                          color:
                                              selectedPlayerCount == playerCount
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'ODAYI OLUŞTUR',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

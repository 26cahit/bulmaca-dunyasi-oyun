import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'room_lobby_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController roomCodeController = TextEditingController();

  final FocusNode roomCodeFocusNode = FocusNode();

  final DatabaseReference roomsRef = FirebaseDatabase.instance.ref('rooms');

  bool isJoining = false;
  bool isLeavingScreen = false;

  Future<void> joinRoom() async {
    final String roomCode = roomCodeController.text.trim().toUpperCase();

    if (roomCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen 6 karakterli oda kodunu gir.',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      isJoining = true;
    });

    try {
      final DatabaseReference roomRef = roomsRef.child(roomCode);

      final DataSnapshot roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        if (!mounted) return;

        setState(() {
          isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oda bulunamadı.', textAlign: TextAlign.center),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final Map<dynamic, dynamic> roomData = Map<dynamic, dynamic>.from(
        roomSnapshot.value as Map,
      );

      final int maxPlayers = (roomData['maxPlayers'] as num?)?.toInt() ?? 2;

      final String roomStatus = roomData['status']?.toString() ?? 'waiting';

      if (roomStatus != 'waiting') {
        if (!mounted) return;

        setState(() {
          isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu odadaki oyun başlamış.',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // ignore: use_build_context_synchronously
      final player = context.read<PlayerProvider>();

      final String playerName = player.playerName.trim();

      if (playerName.isEmpty) {
        if (!mounted) return;

        setState(() {
          isJoining = false;
        });

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
      final DatabaseReference playersRef = roomRef.child('players');

      final DataSnapshot playersSnapshot = await playersRef.get();

      int currentPlayerCount = 0;

      if (playersSnapshot.exists && playersSnapshot.value is Map) {
        final Map<dynamic, dynamic> playersData = Map<dynamic, dynamic>.from(
          playersSnapshot.value as Map,
        );

        currentPlayerCount = playersData.length;
      }

      debugPrint('ODA KODU: $roomCode');

      debugPrint('MEVCUT OYUNCU SAYISI: $currentPlayerCount');

      debugPrint('MAKSIMUM OYUNCU SAYISI: $maxPlayers');

      debugPrint('KATILAN OYUNCU: $playerName');

      if (currentPlayerCount >= maxPlayers) {
        if (!mounted) return;

        setState(() {
          isJoining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bu oda dolu. '
              '$currentPlayerCount / $maxPlayers oyuncu var.',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final DatabaseReference newPlayerRef = playersRef.push();

      await newPlayerRef.set({
        'name': playerName,
        'avatar': player.avatar,
        'joinedAt': ServerValue.timestamp,
        'score': 0,
        'isHost': false,
      });
      final updatedPlayersSnapshot = await playersRef.get();

      int updatedPlayerCount = 0;

      if (updatedPlayersSnapshot.exists) {
        final updatedPlayersData = Map<dynamic, dynamic>.from(
          updatedPlayersSnapshot.value as Map,
        );

        updatedPlayerCount = updatedPlayersData.length;
      }

      if (updatedPlayerCount >= maxPlayers) {
        await roomRef.update({'status': 'ready'});
      }

      if (!mounted) return;

      setState(() {
        isJoining = false;
      });

      isLeavingScreen = true;

      FocusManager.instance.primaryFocus?.unfocus();

      await SystemChannels.textInput.invokeMethod('TextInput.hide');

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              RoomLobbyScreen(roomCode: roomCode, playerId: newPlayerRef.key!),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('FIREBASE ODAYA KATILMA HATASI: $error');

      debugPrint('HATA DETAYI: $stackTrace');

      if (!mounted) return;

      setState(() {
        isJoining = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Odaya katılınamadı: $error',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    roomCodeFocusNode.dispose();

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
          'Odaya Katıl',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                child: const Column(
                  children: [
                    Icon(Icons.login, color: Colors.amber, size: 58),
                    SizedBox(height: 14),
                    Text(
                      'Bir Odaya Katıl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Arkadaşının paylaştığı 6 karakterli oda kodunu gir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      'Oda Kodu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: roomCodeController,
                      focusNode: roomCodeFocusNode,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'ABC123',
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          letterSpacing: 6,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: isJoining ? null : joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isJoining
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'ODAYA KATIL',
                          style: TextStyle(
                            fontSize: 19,
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

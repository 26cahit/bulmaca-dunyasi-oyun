// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import 'room_lobby_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final DatabaseReference roomsRef = FirebaseDatabase.instance.ref('rooms');

  bool joining = false;

  Future<void> joinRoom(String roomId, Map<dynamic, dynamic> roomData) async {
    if (joining) return;

    setState(() {
      joining = true;
    });

    try {
      final player = context.read<PlayerProvider>();

      final String playerName = player.playerName.trim();

      if (playerName.isEmpty) {
        setState(() {
          joining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Önce profil oluşturmalısın.",
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }

      final DatabaseReference roomRef = FirebaseDatabase.instance.ref(
        "rooms/$roomId",
      );

      final DataSnapshot snapshot = await roomRef.get();

      if (!snapshot.exists) {
        setState(() {
          joining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Oda artık mevcut değil.",
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }

      final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final Map<dynamic, dynamic> players = data["players"] == null
          ? {}
          : Map<dynamic, dynamic>.from(data["players"]);

      final int maxPlayers = (data["maxPlayers"] as num?)?.toInt() ?? 2;

      final int currentPlayers = players.length;

      if (currentPlayers >= maxPlayers) {
        setState(() {
          joining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Bu $maxPlayers kişilik oda doludur.\nLütfen başka bir odaya katılmayı deneyin.",
              textAlign: TextAlign.center,
            ),
          ),
        );

        return;
      }

      final DatabaseReference newPlayer = roomRef.child("players").push();

      await newPlayer.set({
        "name": playerName,
        "avatar": player.avatar,
        "score": 0,
        "online": true,
        "status": "waiting",
        "ready": false,
        "isHost": false,
        "joinedAt": ServerValue.timestamp,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RoomLobbyScreen(roomCode: roomId, playerId: newPlayer.key!),
        ),
      );
    } catch (e) {
      setState(() {
        joining = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString(), textAlign: TextAlign.center),
        ),
      );
    }
  }

  @override
  void dispose() {
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
          'Aktif Odalar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: roomsRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
              return const Center(
                child: Text(
                  "Aktif oda bulunamadı.",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              );
            }

            final Map<dynamic, dynamic> rooms = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );
            final now = DateTime.now().millisecondsSinceEpoch;

            rooms.removeWhere((key, value) {
              final data = Map<dynamic, dynamic>.from(value);

              final created = (data["createdAt"] as num?)?.toInt() ?? now;

              final players = data["players"] == null
                  ? {}
                  : Map<dynamic, dynamic>.from(data["players"]);

              if (players.isEmpty) {
                roomsRef.child(key.toString()).remove();
                return true;
              }

              if (now - created > 600000) {
                roomsRef.child(key.toString()).remove();
                return true;
              }

              return false;
            });
            final roomList = rooms.entries.toList();
            roomList.sort((a, b) {
              final roomA = Map<dynamic, dynamic>.from(a.value);
              final roomB = Map<dynamic, dynamic>.from(b.value);

              final playersA = roomA["players"] == null
                  ? {}
                  : Map<dynamic, dynamic>.from(roomA["players"]);

              final playersB = roomB["players"] == null
                  ? {}
                  : Map<dynamic, dynamic>.from(roomB["players"]);

              final currentA = playersA.length;
              final currentB = playersB.length;

              final maxA = (roomA["maxPlayers"] as num?)?.toInt() ?? 2;
              final maxB = (roomB["maxPlayers"] as num?)?.toInt() ?? 2;

              final fullA = currentA >= maxA;
              final fullB = currentB >= maxB;

              if (fullA == fullB) {
                return currentB.compareTo(currentA);
              }

              return fullA ? 1 : -1;
            });
            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: roomList.length,
              itemBuilder: (context, index) {
                final room = roomList[index];

                final String roomId = room.key.toString();

                final Map<dynamic, dynamic> roomData =
                    Map<dynamic, dynamic>.from(room.value);

                if (roomData["status"] != "waiting") {
                  return const SizedBox();
                }
                final int createdAt =
                    (roomData["createdAt"] as num?)?.toInt() ?? 0;

                final int now = DateTime.now().millisecondsSinceEpoch;

                if (now - createdAt > 300000) {
                  roomsRef.child(roomId).remove();
                  return const SizedBox();
                }
                final Map<dynamic, dynamic> players =
                    roomData["players"] == null
                    ? {}
                    : Map<dynamic, dynamic>.from(roomData["players"]);

                final int currentPlayers = players.length;

                final int maxPlayers =
                    (roomData["maxPlayers"] as num?)?.toInt() ?? 2;

                final bool full = currentPlayers >= maxPlayers;

                String hostName = "Oda";

                for (final p in players.values) {
                  final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                    p,
                  );

                  if (data["isHost"] == true) {
                    hostName = data["name"] ?? "Oda";
                    break;
                  }
                }
                String hostAvatar = "🙂";

                for (final p in players.values) {
                  final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                    p,
                  );

                  if (data["isHost"] == true) {
                    hostName = data["name"] ?? "Oda";
                    hostAvatar = data["avatar"] ?? "🙂";
                    break;
                  }
                }
                return Card(
                  color: const Color(0xff1E293B),
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.amber,
                              child: Text(
                                hostAvatar,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$hostName'in Odası",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: full ? Colors.red : Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                full ? "DOLU" : "AKTİF",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            "$maxPlayers Kişilik",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white70),

                            const SizedBox(width: 8),

                            Text(
                              "$currentPlayers / $maxPlayers Oyuncu",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),
                          ],
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: full ? Colors.red : Colors.green,
                            ),
                            onPressed: () {
                              joinRoom(roomId, roomData);
                            },
                            child: Text(
                              full ? "ODA DOLU" : "KATIL",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

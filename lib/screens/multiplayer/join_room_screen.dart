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

      final DatabaseEvent event = await roomRef.once();

      if (!event.snapshot.exists) {
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

      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      if (data["status"] != "waiting") {
        setState(() {
          joining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Oda artık katılmaya kapalı.",
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }

      final Map<dynamic, dynamic> players = data["players"] == null
          ? {}
          : Map<dynamic, dynamic>.from(data["players"]);

      final int maxPlayers = (data["maxPlayers"] as num?)?.toInt() ?? 2;

      if (players.length >= maxPlayers) {
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

      final DatabaseReference newPlayerRef = roomRef.child("players").push();

      await newPlayerRef.set({
        "name": playerName,
        "avatar": player.avatar,
        "score": 0,
        "online": true,
        "status": "waiting",
        "ready": false,
        "isHost": false,
        "joinedAt": ServerValue.timestamp,
      });

      // Oyuncu kopunca kendini silsin
      newPlayerRef.onDisconnect().remove();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RoomLobbyScreen(roomCode: roomId, playerId: newPlayerRef.key!),
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
          stream: roomsRef
              .orderByChild("status")
              .equalTo("waiting")
              .limitToLast(20)
              .onValue,
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

            final int now = DateTime.now().millisecondsSinceEpoch;

            // Eski ve boş odaları temizle
            rooms.removeWhere((key, value) {
              final data = Map<dynamic, dynamic>.from(value);
              final createdAt = (data["createdAt"] as num?)?.toInt() ?? 0;
              final players = data["players"] == null
                  ? {}
                  : Map<dynamic, dynamic>.from(data["players"]);

              if (now - createdAt > 300000 || players.isEmpty) {
                roomsRef.child(key).remove();
                return true;
              }
              return false;
            });

            final roomList = rooms.entries.where((entry) {
              final room = Map<dynamic, dynamic>.from(entry.value);

              if (room["status"] != "waiting") return false;

              final players = room["players"] == null
                  ? {}
                  : Map<dynamic, dynamic>.from(room["players"]);

              if (players.isEmpty) return false;

              bool hostExists = false;
              for (final p in players.values) {
                final player = Map<dynamic, dynamic>.from(p);
                if (player["isHost"] == true) {
                  hostExists = true;
                  break;
                }
              }
              return hostExists;
            }).toList();

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

                final Map<dynamic, dynamic> players =
                    roomData["players"] == null
                    ? {}
                    : Map<dynamic, dynamic>.from(roomData["players"]);

                final int currentPlayers = players.length;
                final int maxPlayers =
                    (roomData["maxPlayers"] as num?)?.toInt() ?? 2;
                final bool full = currentPlayers >= maxPlayers;

                String hostName = "Oda";
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
                              child: Text(
                                "$hostName'in Odası",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: full ? Colors.red : Colors.green,
                            ),
                            onPressed: full
                                ? null
                                : () {
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

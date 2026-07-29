import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';

import 'create_room_screen.dart';
import 'join_room_screen.dart';
import 'quick_match_screen.dart';

class MultiplayerHomeScreen extends StatelessWidget {
  const MultiplayerHomeScreen({super.key});

  Future<String?> askPlayerName(BuildContext context) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    if (playerProvider.playerName.trim().isEmpty) {
      return null;
    }

    return playerProvider.playerName;
  }

  Future<String?> selectGame(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Oyun Dünyasını Seç',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _GameCard(
                  icon: Icons.text_fields,
                  title: 'Kelime Dünyası',
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop('Kelime Dünyası');
                  },
                ),
                const SizedBox(height: 12),
                _GameCard(
                  icon: Icons.psychology,
                  title: 'Zeka Dünyası',
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop('Zeka Dünyası');
                  },
                ),
                const SizedBox(height: 12),
                _GameCard(
                  icon: Icons.school,
                  title: 'Bilgi Dünyası',
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop('Bilgi Dünyası');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> openQuickMatch(BuildContext context) async {
    final String? playerName = await askPlayerName(context);

    if (playerName == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final String? selectedGame = await selectGame(context);

    if (selectedGame == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext routeContext) {
          return QuickMatchScreen(game: selectedGame);
        },
      ),
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
          'Çok Oyunculu',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.groups, color: Colors.amber, size: 58),
                    SizedBox(height: 12),
                    Text(
                      'Arkadaşlarınla Yarış',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Oda oluştur veya hızlı eşleşmeyle rakibini bul.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _MultiplayerCard(
                icon: Icons.add_circle,
                title: 'Oda Oluştur',
                subtitle: 'Arkadaşın için oyun odası aç',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext routeContext) {
                        return const CreateRoomScreen();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _MultiplayerCard(
                icon: Icons.login,
                title: 'Odaya Katıl',
                subtitle: 'Arkadaşının oda kodunu gir',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext routeContext) {
                        return const JoinRoomScreen();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _MultiplayerCard(
                icon: Icons.flash_on,
                title: 'Hızlı Eşleşme',
                subtitle: 'Dünyanı seç ve rakip bul',
                onTap: () {
                  openQuickMatch(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiplayerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MultiplayerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.amber, size: 34),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.amber, size: 31),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

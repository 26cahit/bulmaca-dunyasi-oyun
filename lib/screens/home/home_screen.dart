import 'package:flutter/material.dart';

import '../../services/player_service.dart';
import '../../services/daily_reward_service.dart';
import '../daily_reward_screen.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/game_card.dart';
import '../../widgets/player_info_card.dart';

import '../game/word_game_screen.dart';
import '../../sudoku/screens/sudoku_home_screen.dart';
import '../intelligence/attention_test_screen.dart';
import '../intelligence/intelligence_home_screen.dart';
import '../intelligence/logic_questions_screen.dart';
import '../intelligence/mixed_test_screen.dart';
import '../intelligence/number_logic_screen.dart';
import '../intelligence/quick_intelligence_screen.dart';
import '../../services/update_service.dart';
import '../knowledge/art_literature_screen.dart';
import '../knowledge/geography_screen.dart';
import '../knowledge/history_screen.dart';
import '../knowledge/knowledge_home_screen.dart';
import '../knowledge/mixed_knowledge_screen.dart';
import '../knowledge/science_screen.dart';
import '../knowledge/sports_screen.dart';
import '../../providers/player_provider.dart';
import '../multiplayer/multiplayer_home_screen.dart';
import '../word/word_home_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String>? lastGame;

  bool loadingLastGame = true;
  final DailyRewardService _dailyRewardService = DailyRewardService();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await UpdateService.check();

      if (!mounted) return;

      await _askPlayerName();

      if (!mounted) return;

      await _showTutorial();

      if (!mounted) return;

      await _checkDailyReward();
    });

    _loadLastGame();
  }

  Future<void> _loadLastGame() async {
    final Map<String, String>? savedGame = await PlayerService.getLastGame();

    if (!mounted) {
      return;
    }

    setState(() {
      lastGame = savedGame;
      loadingLastGame = false;
    });
  }

  Future<void> _checkDailyReward() async {
    final canClaim = await _dailyRewardService.canClaimReward();

    if (!canClaim) {
      return;
    }

    if (!mounted) {
      return;
    }

    final day = await _dailyRewardService.currentDay();

    await Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DailyRewardScreen(day: day),
      ),
    );

    await _dailyRewardService.claimReward();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _askPlayerName() async {
    final savedName = await PlayerService.getPlayerName();

    if (savedName.trim().isNotEmpty) {
      return;
    }

    // ignore: use_build_context_synchronously
    final provider = context.read<PlayerProvider>();

    final controller = TextEditingController();

    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Oyuncu Adın",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "İsmini yaz...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                await provider.savePlayerName(controller.text.trim());

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text(
                  "Devam",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTutorial() async {
    final bool seen = await PlayerService.hasSeenTutorial();

    if (seen) {
      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Center(
            child: Text(
              "🎉 Hoş Geldin",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "⭐ XP",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "• Doğru cevap verdikçe kazanırsın.\n"
                  "• Seviye atlamanı sağlar.\n"
                  "• XP harcanmaz.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "🪙 Jeton",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Jetonlarını şu özelliklerde kullanabilirsin:\n\n"
                  "• İpucu Al\n"
                  "• Yanlış Şık Sil\n"
                  "• Süre Ekle\n"
                  "• Soruyu Değiştir\n\n"
                  "Bu özellikler yakında aktif olacak.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                await PlayerService.setTutorialSeen();

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text(
                  "Başla",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLastGameTitle() {
    if (lastGame == null) {
      return '';
    }

    final String gameType = lastGame!['gameType'] ?? '';

    final String section = lastGame!['section'] ?? '';

    final String difficulty = lastGame!['difficulty'] ?? '';

    if (gameType == 'word') {
      if (difficulty == 'easy') {
        return 'Kelime Dünyası • Kolay';
      }

      if (difficulty == 'medium') {
        return 'Kelime Dünyası • Orta';
      }

      if (difficulty == 'hard') {
        return 'Kelime Dünyası • Zor';
      }

      return 'Kelime Dünyası';
    }

    if (gameType == 'intelligence') {
      if (section == 'number_logic') {
        return 'Zeka Dünyası • Sayı Mantığı';
      }

      if (section == 'attention') {
        return 'Zeka Dünyası • Dikkat Testi';
      }

      if (section == 'logic') {
        return 'Zeka Dünyası • Mantık Soruları';
      }

      if (section == 'quick') {
        return 'Zeka Dünyası • Hızlı Zeka';
      }

      if (section == 'mixed') {
        return 'Zeka Dünyası • Karışık Test';
      }

      return 'Zeka Dünyası';
    }

    if (gameType == 'knowledge') {
      if (section == 'geography') {
        return 'Bilgi Dünyası • Coğrafya';
      }

      if (section == 'history') {
        return 'Bilgi Dünyası • Tarih';
      }

      if (section == 'science') {
        return 'Bilgi Dünyası • Bilim';
      }

      if (section == 'art_literature') {
        return 'Bilgi Dünyası • Sanat ve Edebiyat';
      }

      if (section == 'sports') {
        return 'Bilgi Dünyası • Spor';
      }

      if (section == 'mixed') {
        return 'Bilgi Dünyası • Karışık Bilgi';
      }

      return 'Bilgi Dünyası';
    }

    return 'Son Oyun';
  }

  IconData _getLastGameIcon() {
    if (lastGame == null) {
      return Icons.play_arrow_rounded;
    }

    final String gameType = lastGame!['gameType'] ?? '';

    if (gameType == 'word') {
      return Icons.menu_book_rounded;
    }

    if (gameType == 'intelligence') {
      return Icons.psychology_rounded;
    }

    if (gameType == 'knowledge') {
      return Icons.public_rounded;
    }

    return Icons.play_arrow_rounded;
  }

  Future<void> _continueLastGame() async {
    if (lastGame == null) {
      return;
    }

    final String gameType = lastGame!['gameType'] ?? '';

    final String section = lastGame!['section'] ?? '';

    final String difficulty = lastGame!['difficulty'] ?? '';

    Widget? screen;

    if (gameType == 'word') {
      if (difficulty == 'easy' ||
          difficulty == 'medium' ||
          difficulty == 'hard') {
        screen = WordGameScreen(difficulty: difficulty);
      }
    }

    if (gameType == 'intelligence') {
      if (section == 'number_logic') {
        screen = const NumberLogicScreen();
      }

      if (section == 'attention') {
        screen = const AttentionTestScreen();
      }

      if (section == 'logic') {
        screen = const LogicQuestionsScreen();
      }

      if (section == 'quick') {
        screen = const QuickIntelligenceScreen();
      }

      if (section == 'mixed') {
        screen = const MixedTestScreen();
      }
    }

    if (gameType == 'knowledge') {
      if (section == 'geography') {
        screen = const GeographyScreen();
      }

      if (section == 'history') {
        screen = const HistoryScreen();
      }

      if (section == 'science') {
        screen = const ScienceScreen();
      }

      if (section == 'art_literature') {
        screen = const ArtLiteratureScreen();
      }

      if (section == 'sports') {
        screen = const SportsScreen();
      }

      if (section == 'mixed') {
        screen = const MixedKnowledgeScreen();
      }
    }

    if (screen == null) {
      return;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));

    await _loadLastGame();
  }

  Widget _buildContinueCard() {
    if (loadingLastGame || lastGame == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _continueLastGame,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.12),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getLastGameIcon(),
                    color: Colors.amber,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'En Son Kaldığın Bölüm',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getLastGameTitle(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.amber,
                  size: 38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Bulmaca Dünyası",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PlayerInfoCard(),

            _buildContinueCard(),

            GameCard(
              icon: Icons.menu_book,
              title: "Kelime Dünyası",
              subtitle: "100.000+ Bulmaca",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WordHomeScreen()),
                );

                await _loadLastGame();
              },
            ),

            GameCard(
              icon: Icons.psychology,
              title: "Zeka Dünyası",
              subtitle: "50.000+IQ ve Mantık Soruları",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IntelligenceHomeScreen(),
                  ),
                );

                await _loadLastGame();
              },
            ),

            GameCard(
              icon: Icons.public,
              title: "Bilgi Dünyası",
              subtitle: "150.000+ Genel Kültür Sorusu",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KnowledgeHomeScreen(),
                  ),
                );

                await _loadLastGame();
              },
            ),
            GameCard(
              icon: Icons.grid_on,
              title: "Sudoku",
              subtitle: "Binlerce Sudoku Bulmacası",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SudokuHomeScreen()),
                );

                await _loadLastGame();
              },
            ),
            GameCard(
              icon: Icons.groups,
              title: "Çok Oyunculu",
              subtitle: "Online Çok Oyunculu",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MultiplayerHomeScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

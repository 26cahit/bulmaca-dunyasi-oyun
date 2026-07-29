import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/player_service.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/avatar.dart';
import '../screens/avatar/avatar_select_screen.dart';

class PlayerInfoCard extends StatefulWidget {
  const PlayerInfoCard({super.key});

  @override
  State<PlayerInfoCard> createState() {
    return _PlayerInfoCardState();
  }
}

class _PlayerInfoCardState extends State<PlayerInfoCard>
    with TickerProviderStateMixin {
  int coins = 0;
  int xp = 0;
  int level = 1;
  int streak = 0;

  String playerName = '';

  bool isLoading = false;
  bool streakBroken = false;

  late final AnimationController _warningAnimationController;
  late final Animation<double> _warningOpacityAnimation;

  late final AnimationController _fireAnimationController;
  late final Animation<double> _fireScaleAnimation;

  late final AnimationController _levelAnimationController;

  late final AnimationController _xpAnimationController;
  late final Animation<double> _xpMoveAnimation;

  late final AnimationController _coinAnimationController;
  late final Animation<double> _coinScaleAnimation;

  @override
  void initState() {
    super.initState();

    _warningAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _warningOpacityAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _warningAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fireAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);

    _fireScaleAnimation = Tween<double>(begin: 0.88, end: 1.15).animate(
      CurvedAnimation(
        parent: _fireAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _levelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _xpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _xpMoveAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeInOut),
    );

    _coinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _coinScaleAnimation = Tween<double>(begin: 0.92, end: 1.12).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> loadPlayer() async {
    final bool isStreakBroken = await PlayerService.checkStreakStatus();

    final String savedPlayerName = await PlayerService.getPlayerName();

    final int savedCoins = await PlayerService.getCoins();

    final int savedXP = await PlayerService.getXP();

    final int savedLevel = await PlayerService.getLevel();

    final int savedStreak = await PlayerService.getStreak();

    if (!mounted) {
      return;
    }

    setState(() {
      playerName = savedPlayerName;
      coins = savedCoins;
      xp = savedXP;
      level = savedLevel;
      streak = savedStreak;
      streakBroken = isStreakBroken;
      isLoading = false;
    });

    if (streakBroken) {
      _warningAnimationController.repeat(reverse: true);
    } else {
      _warningAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _warningAnimationController.dispose();
    _fireAnimationController.dispose();
    _levelAnimationController.dispose();
    _xpAnimationController.dispose();
    _coinAnimationController.dispose();

    super.dispose();
  }

  Widget buildAnimatedInfoRow({
    required Widget icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 34, height: 34, child: Center(child: icon)),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildFireIcon() {
    return ScaleTransition(
      scale: _fireScaleAnimation,
      child: AnimatedBuilder(
        animation: _fireAnimationController,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(
                    alpha: 0.25 + (_fireAnimationController.value * 0.45),
                  ),
                  blurRadius: 5 + (_fireAnimationController.value * 9),
                  spreadRadius: _fireAnimationController.value * 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: const Text('🔥', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget buildLevelIcon() {
    return AnimatedBuilder(
      animation: _levelAnimationController,
      builder: (BuildContext context, Widget? child) {
        final double angle = -2 * math.pi * _levelAnimationController.value;

        return Transform.rotate(
          angle: angle,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: const Text('🏆', style: TextStyle(fontSize: 23)),
    );
  }

  Widget buildXPIcon() {
    return AnimatedBuilder(
      animation: _xpAnimationController,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(_xpMoveAnimation.value, 0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(
                    alpha: 0.25 + (_xpAnimationController.value * 0.50),
                  ),
                  blurRadius: 5 + (_xpAnimationController.value * 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: const Text('⭐', style: TextStyle(fontSize: 23)),
    );
  }

  Widget buildCoinIcon() {
    return ScaleTransition(
      scale: _coinScaleAnimation,
      child: AnimatedBuilder(
        animation: _coinAnimationController,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(
                    alpha: 0.25 + (_coinAnimationController.value * 0.55),
                  ),
                  blurRadius: 6 + (_coinAnimationController.value * 12),
                  spreadRadius: _coinAnimationController.value * 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: const Text('💰', style: TextStyle(fontSize: 23)),
      ),
    );
  }

  Widget buildStreakWarning() {
    return FadeTransition(
      opacity: _warningOpacityAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.70),
            width: 1.2,
          ),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 23,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Oyuna ara verdiğiniz için günlük oyun seriniz sıfırlandı.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    final String visiblePlayerName = player.playerName.trim().isEmpty
        ? 'Misafir Oyuncu'
        : player.playerName.trim();
    final bool isCustomAvatar =
        player.avatar.startsWith("http://") ||
        player.avatar.startsWith("https://");

    final AvatarModel selectedAvatar = avatars.firstWhere(
      (avatar) => avatar.emoji == player.avatar,
      orElse: () => avatars.first,
    );
    return Card(
      color: const Color(0xFF1E293B),
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👋 Hoş Geldin',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AvatarSelectScreen(),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: .25),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isCustomAvatar
                          ? ClipOval(
                              child: Image.network(
                                player.avatar,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) {
                                    return child;
                                  }

                                  return const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint("RESİM HATASI");
                                  debugPrint(error.toString());

                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 34,
                                  );
                                },
                              ),
                            )
                          : Text(
                              selectedAvatar.emoji,
                              style: const TextStyle(fontSize: 34),
                            ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visiblePlayerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      const Text(
                        "Avatarını değiştirmek için dokun",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            buildAnimatedInfoRow(
              icon: buildFireIcon(),
              title: 'Günlük Seri',
              subtitle: 'Her gün giriş yaparak artır.',
              value: '${player.streak} Gün',
            ),
            if (streakBroken) buildStreakWarning(),
            const SizedBox(height: 12),
            buildAnimatedInfoRow(
              icon: buildLevelIcon(),
              title: 'Seviye',
              subtitle: 'XP kazandıkça yükselir.',
              value: '${player.level}',
            ),
            const SizedBox(height: 12),
            buildAnimatedInfoRow(
              icon: buildXPIcon(),
              title: 'XP',
              subtitle: 'Seviye atlamak için kullanılır.',
              value: '${player.xp}',
            ),
            const SizedBox(height: 12),
            buildAnimatedInfoRow(
              icon: buildCoinIcon(),
              title: 'Jeton',
              subtitle: 'İpucu ve özel özelliklerde kullanılır.',
              value: '${player.coins}',
            ),
          ],
        ),
      ),
    );
  }
}

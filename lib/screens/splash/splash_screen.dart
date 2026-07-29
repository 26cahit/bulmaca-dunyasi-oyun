import 'dart:math' as math;
import '../../services/update_service.dart';
import 'package:flutter/material.dart';

import '../../services/sound_service.dart';
import '../home/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _glow;

  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;

  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;

  bool _isLeaving = false;
  String version = "";
  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoRotation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glow = Tween<double>(begin: 0.20, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.55, 0.90, curve: Curves.easeIn),
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 3.2).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _loadVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.check();
    });
    Future.delayed(const Duration(milliseconds: 50), _startSplash);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      version = "v${info.version}";
    });
  }

  Future<void> _startSplash() async {
    if (!mounted) return;

    await SoundService.playSplashLogo();

    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    await SoundService.playSplashTitle();

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    _glowController.stop();

    setState(() {
      _isLeaving = true;
    });

    await SoundService.playSplashExit();

    await _exitController.forward();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _glowController,
        _exitController,
      ]),
      builder: (context, child) {
        final double scale = _isLeaving ? _exitScale.value : _logoScale.value;

        final double opacity = _isLeaving ? _exitOpacity.value : 1.0;

        final double rotation = _logoRotation.value * math.pi;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(
                        alpha: 0.20 + (_glow.value * 0.55),
                      ),
                      blurRadius: 15 + (_glow.value * 30),
                      spreadRadius: 2 + (_glow.value * 7),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.extension_rounded,
                      color: Color(0xFF0F172A),
                      size: 100,
                    ),
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 47),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final int activeDot = (_glowController.value * 3).floor().clamp(0, 2);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final bool isActive = index == activeDot;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isActive ? 14 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.amber : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    SoundService.stopSplash();

    _logoController.dispose();
    _glowController.dispose();
    _exitController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),

                const SizedBox(height: 26),

                FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: [
                      const Text(
                        "Developed by",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 6),

                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFFFFF59D),
                              Color(0xFFFFD54F),
                              Color(0xFFFFA000),
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          "CAHİT ACAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        version,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const Column(
                      children: [
                        Text(
                          'BULMACA DÜNYASI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),

                        SizedBox(height: 12),

                        Text(
                          'DÜŞÜN • ÖĞREN • YARIŞ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 55),

                FadeTransition(
                  opacity: _textOpacity,
                  child: _buildLoadingDots(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

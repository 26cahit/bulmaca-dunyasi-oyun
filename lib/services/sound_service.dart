import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _effectPlayer = AudioPlayer();
  static final AudioPlayer _wheelPlayer = AudioPlayer();
  static final AudioPlayer _tickPlayer = AudioPlayer();

  static final AudioPlayer _splashLogoPlayer = AudioPlayer();
  static final AudioPlayer _splashTitlePlayer = AudioPlayer();
  static final AudioPlayer _splashExitPlayer = AudioPlayer();

  static Future<void> playCorrect() async {
    await _effectPlayer.stop();

    await _effectPlayer.play(AssetSource('sounds/correct.mp3'));
  }

  static Future<void> playWrong() async {
    await _effectPlayer.stop();

    await _effectPlayer.play(AssetSource('sounds/wrong.mp3'));
  }

  static Future<void> playWheel() async {
    await _wheelPlayer.stop();

    await _wheelPlayer.setReleaseMode(ReleaseMode.loop);

    await _wheelPlayer.play(AssetSource('sounds/wheel.mp3'));
  }

  static Future<void> stopWheel() async {
    await _wheelPlayer.stop();

    await _wheelPlayer.setReleaseMode(ReleaseMode.release);
  }

  static Future<void> playTick() async {
    await _tickPlayer.stop();

    await _tickPlayer.play(AssetSource('sounds/tick.mp3'));
  }

  static Future<void> stopTick() async {
    await _tickPlayer.stop();
  }

  static Future<void> playSplashLogo() async {
    try {
      await _splashLogoPlayer.stop();

      await _splashLogoPlayer.play(AssetSource('sounds/splash_logo.mp3'));
    } catch (_) {}
  }

  static Future<void> playSplashTitle() async {
    try {
      await _splashTitlePlayer.stop();

      await _splashTitlePlayer.play(AssetSource('sounds/splash_title.mp3'));
    } catch (_) {}
  }

  static Future<void> playSplashExit() async {
    try {
      await _splashExitPlayer.stop();

      await _splashExitPlayer.play(AssetSource('sounds/splash_exit.mp3'));
    } catch (_) {}
  }

  static Future<void> stopSplash() async {
    try {
      await _splashLogoPlayer.stop();
      await _splashTitlePlayer.stop();
      await _splashExitPlayer.stop();
    } catch (_) {}
  }
}

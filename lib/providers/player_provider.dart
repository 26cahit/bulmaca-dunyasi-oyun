import 'package:flutter/material.dart';
import 'dart:io';
import '../services/player_service.dart';
import '../services/avatar_upload_service.dart';

class PlayerProvider extends ChangeNotifier {
  String playerName = '';
  String avatar = "👦";
  int xp = 0;
  int coins = 0;
  int level = 1;
  int streak = 0;

  Future<void> loadPlayer() async {
    playerName = await PlayerService.getPlayerName();
    avatar = await PlayerService.getAvatar();
    xp = await PlayerService.getXP();
    coins = await PlayerService.getCoins();
    level = await PlayerService.getLevel();
    streak = await PlayerService.getStreak();

    notifyListeners();
  }

  Future<void> savePlayerName(String value) async {
    playerName = value.trim();

    await PlayerService.savePlayerName(playerName);

    notifyListeners();
  }

  Future<void> addReward({required int addXp, required int addCoins}) async {
    debugPrint("ÖNCE XP = $xp");
    debugPrint("ÖNCE COINS = $coins");

    xp += addXp;
    coins += addCoins;

    debugPrint("SONRA XP = $xp");
    debugPrint("SONRA COINS = $coins");

    await PlayerService.saveXP(xp);
    await PlayerService.saveCoins(coins);

    debugPrint("KAYDEDİLEN XP = ${await PlayerService.getXP()}");
    debugPrint("KAYDEDİLEN COINS = ${await PlayerService.getCoins()}");

    notifyListeners();
  }

  Future<void> saveLevel(int value) async {
    level = value;

    await PlayerService.saveLevel(level);

    notifyListeners();
  }

  Future<void> saveStreak(int value) async {
    streak = value;

    await PlayerService.saveStreak(streak);

    notifyListeners();
  }

  Future<void> saveAvatar(String avatarId) async {
    avatar = avatarId;

    await PlayerService.saveAvatar(avatarId);

    notifyListeners();
  }

  Future<void> saveCustomAvatar(File file) async {
    try {
      final avatarUrl = await AvatarUploadService.uploadAvatar(file);

      avatar = avatarUrl;

      await PlayerService.saveAvatar(avatarUrl);

      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print("HATA");
      // ignore: avoid_print
      print(e);
    }
  }
}

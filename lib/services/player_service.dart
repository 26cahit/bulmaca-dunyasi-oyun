import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlayerService {
  static const String _playerNameKey = 'playerName';
  static const String _avatarKey = 'avatar';
  static const String _xpKey = 'xp';
  static const String _coinsKey = 'coins';
  static const String _levelKey = 'level';
  static const String _streakKey = 'streak';
  static const String _lastGameDateKey = 'lastGameDate';
  static const String _streakBrokenKey = 'streakBroken';

  static const String _lastGameTypeKey = 'lastGameType';
  static const String _lastGameSectionKey = 'lastGameSection';
  static const String _lastGameDifficultyKey = 'lastGameDifficulty';
  static const String _hasLastGameKey = 'hasLastGame';

  static const String _gameProgressPrefix = 'gameProgress_';

  static Future<void> savePlayerName(String playerName) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_playerNameKey, playerName);
  }

  static Future<void> saveAvatar(String avatarId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_avatarKey, avatarId);
  }

  static Future<String> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_avatarKey) ?? "Avatar1";
  }

  static Future<String> getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_playerNameKey) ?? '';
  }

  static Future<void> saveXP(int xp) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_xpKey, xp);
  }

  static Future<int> getXP() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<void> saveCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_coinsKey, coins);
  }

  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_coinsKey) ?? 0;
  }

  static Future<void> saveLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_levelKey, level);
  }

  static Future<int> getLevel() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_levelKey) ?? 1;
  }

  static Future<void> saveStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_streakKey, streak);
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_streakKey) ?? 0;
  }

  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('hasSeenTutorial') ?? false;
  }

  static Future<void> setTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('hasSeenTutorial', true);
  }

  static Future<String?> getLastGameDate() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_lastGameDateKey);
  }

  static Future<void> saveLastGameDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();

    final String dateText = _dateToText(date);

    await prefs.setString(_lastGameDateKey, dateText);
  }

  static Future<bool> getStreakBroken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_streakBrokenKey) ?? false;
  }

  static Future<void> setStreakBroken(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_streakBrokenKey, value);
  }

  static Future<void> saveLastGame({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    if (gameType == 'multiplayer') {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_lastGameTypeKey, gameType);

    await prefs.setString(_lastGameSectionKey, section);

    await prefs.setString(_lastGameDifficultyKey, difficulty);

    await prefs.setBool(_hasLastGameKey, true);
  }

  static Future<bool> hasLastGame() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_hasLastGameKey) ?? false;
  }

  static Future<String> getLastGameType() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_lastGameTypeKey) ?? '';
  }

  static Future<String> getLastGameSection() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_lastGameSectionKey) ?? '';
  }

  static Future<String> getLastGameDifficulty() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_lastGameDifficultyKey) ?? '';
  }

  static Future<Map<String, String>?> getLastGame() async {
    final prefs = await SharedPreferences.getInstance();

    final bool hasGame = prefs.getBool(_hasLastGameKey) ?? false;

    if (!hasGame) {
      return null;
    }

    final String gameType = prefs.getString(_lastGameTypeKey) ?? '';

    final String section = prefs.getString(_lastGameSectionKey) ?? '';

    final String difficulty = prefs.getString(_lastGameDifficultyKey) ?? '';

    if (gameType.isEmpty || section.isEmpty) {
      return null;
    }

    return {'gameType': gameType, 'section': section, 'difficulty': difficulty};
  }

  static Future<void> clearLastGame() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_lastGameTypeKey);

    await prefs.remove(_lastGameSectionKey);

    await prefs.remove(_lastGameDifficultyKey);

    await prefs.setBool(_hasLastGameKey, false);
  }

  static String _createProgressKey({
    required String gameType,
    required String section,
    String difficulty = '',
  }) {
    return '$_gameProgressPrefix'
        '${gameType}_'
        '${section}_'
        '$difficulty';
  }

  static Future<void> saveGameProgress({
    required String gameType,
    required String section,
    String difficulty = '',
    required int questionNumber,
    required int score,
    required int earnedXp,
    required int earnedCoins,
    required List<int> questionOrder,
    Map<String, dynamic> extraData = const {},
  }) async {
    if (gameType == 'multiplayer') {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final String progressKey = _createProgressKey(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    final Map<String, dynamic> progress = {
      'gameType': gameType,
      'section': section,
      'difficulty': difficulty,
      'questionNumber': questionNumber,
      'score': score,
      'earnedXp': earnedXp,
      'earnedCoins': earnedCoins,
      'questionOrder': questionOrder,
      'extraData': extraData,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(progressKey, jsonEncode(progress));

    await saveLastGame(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );
  }

  static Future<Map<String, dynamic>?> getGameProgress({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final String progressKey = _createProgressKey(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    final String? progressText = prefs.getString(progressKey);

    if (progressText == null || progressText.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(progressText);

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasGameProgress({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final String progressKey = _createProgressKey(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    return prefs.containsKey(progressKey);
  }

  static Future<void> clearGameProgress({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final String progressKey = _createProgressKey(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    await prefs.remove(progressKey);
  }

  static Future<void> clearLastGameAndProgress() async {
    final Map<String, String>? lastGame = await getLastGame();

    if (lastGame != null) {
      await clearGameProgress(
        gameType: lastGame['gameType'] ?? '',
        section: lastGame['section'] ?? '',
        difficulty: lastGame['difficulty'] ?? '',
      );
    }

    await clearLastGame();
  }

  static Future<List<int>> getSavedQuestionOrder({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final Map<String, dynamic>? progress = await getGameProgress(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    if (progress == null) {
      return [];
    }

    final dynamic savedOrder = progress['questionOrder'];

    if (savedOrder is! List) {
      return [];
    }

    return savedOrder.map((item) => item as int).toList();
  }

  static Future<int> getSavedQuestionNumber({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final Map<String, dynamic>? progress = await getGameProgress(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    if (progress == null) {
      return 0;
    }

    return progress['questionNumber'] as int? ?? 0;
  }

  static Future<int> getSavedScore({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final Map<String, dynamic>? progress = await getGameProgress(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    if (progress == null) {
      return 0;
    }

    return progress['score'] as int? ?? 0;
  }

  static Future<int> getSavedEarnedXp({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final Map<String, dynamic>? progress = await getGameProgress(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    if (progress == null) {
      return 0;
    }

    return progress['earnedXp'] as int? ?? 0;
  }

  static Future<int> getSavedEarnedCoins({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final Map<String, dynamic>? progress = await getGameProgress(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    if (progress == null) {
      return 0;
    }

    return progress['earnedCoins'] as int? ?? 0;
  }

  static Future<Map<String, dynamic>> getSavedExtraData({
    required String gameType,
    required String section,
    String difficulty = '',
  }) async {
    final Map<String, dynamic>? progress = await getGameProgress(
      gameType: gameType,
      section: section,
      difficulty: difficulty,
    );

    if (progress == null) {
      return {};
    }

    final dynamic extraData = progress['extraData'];

    if (extraData is! Map) {
      return {};
    }

    return Map<String, dynamic>.from(extraData);
  }

  static Future<bool> checkStreakStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final String? lastGameDateText = prefs.getString(_lastGameDateKey);

    if (lastGameDateText == null || lastGameDateText.isEmpty) {
      return prefs.getBool(_streakBrokenKey) ?? false;
    }

    final DateTime? lastGameDate = DateTime.tryParse(lastGameDateText);

    if (lastGameDate == null) {
      return false;
    }

    final DateTime today = _onlyDate(DateTime.now());

    final DateTime lastGameDay = _onlyDate(lastGameDate);

    final int dayDifference = today.difference(lastGameDay).inDays;

    if (dayDifference > 1) {
      await prefs.setInt(_streakKey, 0);

      await prefs.setBool(_streakBrokenKey, true);

      return true;
    }

    return prefs.getBool(_streakBrokenKey) ?? false;
  }

  static Future<void> completeGameToday() async {
    final prefs = await SharedPreferences.getInstance();

    final DateTime today = _onlyDate(DateTime.now());

    final String? lastGameDateText = prefs.getString(_lastGameDateKey);

    int currentStreak = prefs.getInt(_streakKey) ?? 0;

    if (lastGameDateText == null || lastGameDateText.isEmpty) {
      currentStreak = 1;
    } else {
      final DateTime? lastGameDate = DateTime.tryParse(lastGameDateText);

      if (lastGameDate == null) {
        currentStreak = 1;
      } else {
        final DateTime lastGameDay = _onlyDate(lastGameDate);

        final int dayDifference = today.difference(lastGameDay).inDays;

        if (dayDifference == 0) {
        } else if (dayDifference == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }
    }

    await prefs.setInt(_streakKey, currentStreak);

    await prefs.setString(_lastGameDateKey, _dateToText(today));

    await prefs.setBool(_streakBrokenKey, false);
  }

  static DateTime _onlyDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dateToText(DateTime date) {
    final DateTime cleanDate = _onlyDate(date);

    return cleanDate.toIso8601String();
  }
}

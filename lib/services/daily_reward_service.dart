import 'package:shared_preferences/shared_preferences.dart';

class DailyRewardService {
  static const _lastLogin = "last_login";
  static const _day = "reward_day";

  Future<bool> canClaimReward() async {
    final prefs = await SharedPreferences.getInstance();

    final last = prefs.getString(_lastLogin);

    if (last == null) return true;

    final lastDate = DateTime.parse(last);

    final now = DateTime.now();

    return lastDate.year != now.year ||
        lastDate.month != now.month ||
        lastDate.day != now.day;
  }

  Future<int> currentDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_day) ?? 1;
  }

  Future<void> claimReward() async {
    final prefs = await SharedPreferences.getInstance();

    int day = prefs.getInt(_day) ?? 1;

    if (day < 7) {
      day++;
    } else {
      day = 1;
    }

    await prefs.setInt(_day, day);

    await prefs.setString(_lastLogin, DateTime.now().toIso8601String());
  }
}

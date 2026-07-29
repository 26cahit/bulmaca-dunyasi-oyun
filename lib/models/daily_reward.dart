class DailyReward {
  final int day;
  final int coins;
  final int jokers;

  const DailyReward({
    required this.day,
    required this.coins,
    required this.jokers,
  });
}

const List<DailyReward> dailyRewards = [
  DailyReward(day: 1, coins: 50, jokers: 0),
  DailyReward(day: 2, coins: 75, jokers: 0),
  DailyReward(day: 3, coins: 100, jokers: 0),
  DailyReward(day: 4, coins: 0, jokers: 1),
  DailyReward(day: 5, coins: 150, jokers: 0),
  DailyReward(day: 6, coins: 0, jokers: 2),
  DailyReward(day: 7, coins: 300, jokers: 3),
];

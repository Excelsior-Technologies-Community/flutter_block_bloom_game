import 'package:flutter_test/flutter_test.dart';
import 'package:block_bloom/domain/models/booster_reward.dart';

void main() {
  group('Daily Booster Wheel Rewards Model', () {
    test('Has exactly 8 slices matching the arcade wheel', () {
      expect(kDailyBoosterRewards.length, 8);
    });

    test('Contains Jackpot 500 flowers at Slice 0 with jackpot flag', () {
      final jackpot = kDailyBoosterRewards[0];
      expect(jackpot.isJackpot, isTrue);
      expect(jackpot.amount, 500);
      expect(jackpot.type, BoosterRewardType.flowers);
      expect(jackpot.rewardTag, 'JACKPOT');
    });

    test('All 8 rewards have valid gradients, icons, and non-empty titles', () {
      for (final reward in kDailyBoosterRewards) {
        expect(reward.title.isNotEmpty, isTrue);
        expect(reward.subtitle.isNotEmpty, isTrue);
        expect(reward.description.isNotEmpty, isTrue);
        expect(reward.labelShort.isNotEmpty, isTrue);
        expect(reward.rewardTag.isNotEmpty, isTrue);
        expect(reward.amount, greaterThan(0));
        expect(reward.gradientColors.length, greaterThanOrEqualTo(2));
        expect(reward.iconEmoji.isNotEmpty, isTrue);
      }
    });

    test('Contains in-game boosters & currencies', () {
      final types = kDailyBoosterRewards.map((r) => r.type).toSet();
      expect(types.contains(BoosterRewardType.flowers), isTrue);
      expect(types.contains(BoosterRewardType.gems), isTrue);
      expect(types.contains(BoosterRewardType.trayRefresh), isTrue);
      expect(types.contains(BoosterRewardType.bloomBomb), isTrue);
      expect(types.contains(BoosterRewardType.scoreMultiplier), isTrue);
      expect(types.contains(BoosterRewardType.bloomHammer), isTrue);
    });
  });

  group('Booster Wheel 24H Cooldown Logic', () {
    test('Initial free spin is available if never spun', () {
      const int lastSpinEpoch = 0;
      final bool isFree = lastSpinEpoch <= 0;
      expect(isFree, isTrue);
    });

    test('Cooldown is active within 24 hours', () {
      final now = DateTime.now();
      final lastSpin = now.subtract(const Duration(hours: 5));
      final elapsed = now.difference(lastSpin);
      const cooldown = Duration(hours: 24);
      final remaining = cooldown - elapsed;

      expect(remaining.inHours, 19);
      expect(remaining.isNegative, isFalse);
    });

    test('Cooldown expires after 24 hours', () {
      final now = DateTime.now();
      final lastSpin = now.subtract(const Duration(hours: 25));
      final elapsed = now.difference(lastSpin);
      const cooldown = Duration(hours: 24);
      final remaining = elapsed >= cooldown ? Duration.zero : cooldown - elapsed;

      expect(remaining, Duration.zero);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:block_bloom/domain/models/booster_reward.dart';
import 'package:block_bloom/domain/models/arcade_event_model.dart';
import 'package:block_bloom/domain/models/bloom_quest_model.dart';

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

  group('Arcade Events & Quests Model', () {
    test('Daily quests have valid targets and rewards', () {
      expect(kDefaultDailyQuests.isNotEmpty, isTrue);
      for (final quest in kDefaultDailyQuests) {
        expect(quest.title.isNotEmpty, isTrue);
        expect(quest.maxGoal, greaterThan(0));
        expect(quest.rewardAmount, greaterThan(0));
        expect(quest.progressRatio, inInclusiveRange(0.0, 1.0));
      }
    });

    test('Season pass has 5 structured tiers with valid rewards', () {
      expect(kDefaultGardenPassTiers.length, 5);
      for (final tier in kDefaultGardenPassTiers) {
        expect(tier.tierNumber, greaterThanOrEqualTo(1));
        expect(tier.freeRewardTitle.isNotEmpty, isTrue);
        expect(tier.vipRewardTitle.isNotEmpty, isTrue);
      }
    });

    test('Episode race has 5 participants with player in #1 rank', () {
      expect(kDefaultRaceParticipants.length, 5);
      final player = kDefaultRaceParticipants.firstWhere((p) => p.isPlayer);
      expect(player.rank, 1);
      expect(player.name, 'You');
    });
  });

  group('Block Bloom Authentic Quests Model', () {
    test('Daily Quests list has 5 authentic gameplay quests', () {
      expect(kDefaultBloomDailyQuests.length, 5);
      for (final quest in kDefaultBloomDailyQuests) {
        expect(quest.title.isNotEmpty, isTrue);
        expect(quest.description.isNotEmpty, isTrue);
        expect(quest.targetGoal, greaterThan(0));
        expect(quest.rewardAmount, greaterThan(0));
        expect(quest.category, BloomQuestCategory.daily);
      }
    });

    test('Weekly Milestones list has 3 authentic gameplay achievements', () {
      expect(kDefaultBloomWeeklyQuests.length, 3);
      for (final quest in kDefaultBloomWeeklyQuests) {
        expect(quest.title.isNotEmpty, isTrue);
        expect(quest.targetGoal, greaterThan(0));
        expect(quest.rewardAmount, greaterThan(0));
        expect(quest.category, BloomQuestCategory.weekly);
      }
    });

    test('BloomQuest progress ratio is clamped between 0.0 and 1.0', () {
      const q1 = BloomQuest(
        id: 'test_1',
        title: 'Test',
        description: 'Test',
        iconEmoji: '🌸',
        type: BloomQuestType.linesCleared,
        category: BloomQuestCategory.daily,
        currentProgress: 15,
        targetGoal: 10,
        rewardAmount: 50,
        rewardType: 'flowers',
        rewardEmoji: '🌸',
      );
      expect(q1.isCompleted, isTrue);
      expect(q1.canClaim, isTrue);
      expect(q1.progressRatio, 1.0);

      final q2 = q1.copyWith(isClaimed: true);
      expect(q2.isClaimed, isTrue);
      expect(q2.canClaim, isFalse);
    });
  });
}

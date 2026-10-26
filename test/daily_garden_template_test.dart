import 'package:flutter_test/flutter_test.dart';
import 'package:block_bloom/domain/models/board_template.dart';
import 'package:block_bloom/domain/use_cases/level_generator.dart';

void main() {
  group('Daily Garden Templates & Generation', () {
    test('All 31 daily templates are defined, 8x8, and meet high-scoring criteria', () {
      expect(BoardTemplate.dailyTemplates.length, equals(31));

      for (int i = 0; i < BoardTemplate.dailyTemplates.length; i++) {
        final template = BoardTemplate.dailyTemplates[i];
        expect(template.rows, equals(8), reason: '${template.name} rows');
        expect(template.cols, equals(8), reason: '${template.name} cols');
        expect(template.layout.length, equals(8), reason: '${template.name} layout height');

        for (int r = 0; r < 8; r++) {
          expect(template.layout[r].length, equals(8), reason: '${template.name} row $r length');
        }

        // Each template should have ample playable tiles (>= 48) for high scoring
        expect(
          template.totalPlayableCells,
          greaterThanOrEqualTo(48),
          reason: '${template.name} total playable cells (${template.totalPlayableCells}) should be >= 48 for score more',
        );

        expect(template.name.isNotEmpty, isTrue);
        expect(template.emoji.isNotEmpty, isTrue);
        expect(template.id.isNotEmpty, isTrue);
      }
    });

    test('getDailyTemplate returns distinct template for each day of the month', () {
      final seenIds = <String>{};
      for (int day = 1; day <= 31; day++) {
        final date = DateTime(2026, 10, day);
        final template = BoardTemplate.getDailyTemplate(date);
        expect(seenIds.contains(template.id), isFalse, reason: 'Duplicate template for day $day: ${template.id}');
        seenIds.add(template.id);
      }
      expect(seenIds.length, equals(31));
    });

    test('LevelGenerator.generateDaily produces GameLevel with active BoardTemplate', () {
      final generator = LevelGenerator();
      final date = DateTime(2026, 10, 26); // Oct 26
      final level = generator.generateDaily(date);

      final expectedTemplate = BoardTemplate.getDailyTemplate(date);
      expect(level.template, isNotNull);
      expect(level.template!.id, equals(expectedTemplate.id));
      expect(level.gridSize, equals(8));

      // Verify that blocked cells in initialGrid match the template voids (-1)
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (!expectedTemplate.isPlayable(r, c)) {
            expect(level.initialGrid[r][c], equals(-1), reason: 'Void cell at ($r, $c)');
          } else {
            expect(level.initialGrid[r][c], equals(0), reason: 'Playable cell at ($r, $c)');
          }
        }
      }
    });
  });
}

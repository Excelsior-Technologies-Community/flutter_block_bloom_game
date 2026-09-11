import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/data/repositories/progress_repository.dart';
import 'package:block_bloom/data/services/hive_service.dart';
import 'package:block_bloom/domain/use_cases/level_generator.dart';
import 'package:block_bloom/ui/features/game/view_models/game_view_model.dart';
import 'package:block_bloom/ui/features/home/view_models/home_view_model.dart';
import 'package:block_bloom/data/services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final progressRepositoryProvider = ChangeNotifierProvider<ProgressRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ProgressRepository(hiveService: hiveService);
});

final levelGeneratorProvider = Provider<LevelGenerator>((ref) {
  return LevelGenerator();
});

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeViewModelState>((ref) {
      final progressRepository = ref.read(progressRepositoryProvider);
      return HomeViewModel(progressRepository: progressRepository);
    });

final gameViewModelProvider =
    StateNotifierProvider.autoDispose<GameViewModel, GameViewModelState>((ref) {
      final progressRepository = ref.read(progressRepositoryProvider);
      final levelGenerator = ref.read(levelGeneratorProvider);
      return GameViewModel(
        progressRepository: progressRepository,
        levelGenerator: levelGenerator,
      );
    });

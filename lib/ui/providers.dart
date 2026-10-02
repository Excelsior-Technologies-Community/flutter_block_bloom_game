import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/domain/models/app_user.dart';
import 'package:block_bloom/data/repositories/progress_repository.dart';
import 'package:block_bloom/data/services/hive_service.dart';
import 'package:block_bloom/domain/use_cases/level_generator.dart';
import 'package:block_bloom/ui/features/game/view_models/game_view_model.dart';
import 'package:block_bloom/ui/features/home/view_models/home_view_model.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/data/services/auth_service.dart';
import 'package:block_bloom/ui/features/auth/view_models/auth_view_model.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthViewModelState>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthViewModel(authService);
    });

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final progressRepositoryProvider = ChangeNotifierProvider<ProgressRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final repo = ProgressRepository(hiveService: hiveService);

  void syncUser(AppUser? user) {
    if (user != null && user.uid.isNotEmpty) {
      repo.setCurrentUser(user.uid);
      final userName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email != null && user.email!.contains('@')
              ? user.email!.split('@').first
              : '');
      repo.getProgress().then((progress) {
        repo.saveProgress(progress, displayName: userName);
      });
    } else {
      repo.setCurrentUser(null);
    }
  }

  ref.listen<AuthViewModelState>(authViewModelProvider, (previous, next) {
    syncUser(next.user);
  });

  final currentUser = ref.read(authViewModelProvider).user;
  if (currentUser != null && currentUser.uid.isNotEmpty) {
    syncUser(currentUser);
  }

  return repo;
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

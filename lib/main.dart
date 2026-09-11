import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/data/services/hive_service.dart';
import 'package:block_bloom/ui/features/splash/views/splash_view.dart';
import 'package:block_bloom/ui/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hiveService = HiveService();
  await hiveService.init();

  await AudioService.instance.init();
  await AudioService.instance.startBackgroundMusic();

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
      ],
      child: const BlockBloomApp(),
    ),
  );
}

class BlockBloomApp extends StatelessWidget {
  const BlockBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Bloom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
        useMaterial3: true,
      ),
      home: const SplashView(),
    );
  }
}

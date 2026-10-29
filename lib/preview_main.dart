// 仅用于截图/预览的入口，不参与正式打包。
// 用法：flutter build web -t lib/preview_main.dart
// 打开 index.html?screen=detail&theme=dark 之类。
import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'data/word_families.dart';
import 'screens/add_pair_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/family_screen.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/settings_screen.dart';
import 'services/progress_store.dart';
import 'services/user_pairs_store.dart';
import 'theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final params = Uri.base.queryParameters;
    final screen = params['screen'] ?? 'home';
    final dark = params['theme'] == 'dark';

    final progress = ProgressStore()..load();
    final userPairs = UserPairsStore()..load();

    final Widget home = switch (screen) {
      'detail' => DetailScreen(
          pair: samplePairs.first,
          store: progress,
          userPairs: userPairs,
        ),
      'quiz' => QuizScreen(pairs: samplePairs),
      'quiz-right' => QuizScreen(pairs: samplePairs, previewAnswer: 'right'),
      'quiz-wrong' => QuizScreen(pairs: samplePairs, previewAnswer: 'wrong'),
      'add' => const AddPairScreen(),
      'family' => FamilyScreen(family: wordFamilies.first),
      'settings' => SettingsScreen(progress: progress, userPairs: userPairs),
      _ => const HomeScreen(pairs: samplePairs),
    };

    return MaterialApp(
      title: '预览',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Palette.light, Brightness.light),
      darkTheme: buildTheme(Palette.dark, Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
      builder: (context, child) {
        // 预览时把界面锁成手机宽度，方便截图。
        return ColoredBox(
          color: const Color(0xFFE6E3DB),
          child: Center(
            child: SizedBox(width: 430, child: child),
          ),
        );
      },
    );
  }
}

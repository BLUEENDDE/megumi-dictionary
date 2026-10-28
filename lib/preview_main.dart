// 仅用于截图/预览的入口，不参与正式打包。
// 用法：先 flutter build web -t lib/preview_main.dart，
// 再打开 index.html?screen=detail 或 ?screen=quiz。
import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
import 'services/progress_store.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = Uri.base.queryParameters['screen'] ?? 'home';
    final store = ProgressStore()..load();

    final Widget home = switch (screen) {
      'detail' => DetailScreen(pair: samplePairs.first, store: store),
      'quiz' => QuizScreen(pairs: samplePairs),
      'quiz-right' => QuizScreen(pairs: samplePairs, previewAnswer: 'right'),
      'quiz-wrong' => QuizScreen(pairs: samplePairs, previewAnswer: 'wrong'),
      _ => const HomeScreen(pairs: samplePairs),
    };

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6F),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: '预览',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F5F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F5F1),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1B18),
          ),
          iconTheme: IconThemeData(color: Color(0xFF1C1B18)),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),
      ),
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

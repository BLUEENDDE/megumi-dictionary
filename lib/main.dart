import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6F),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: '印尼语易混词',
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
      home: const HomeScreen(pairs: samplePairs),
    );
  }
}

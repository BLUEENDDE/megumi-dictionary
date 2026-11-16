import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/screens/word_quiz_screen.dart';
import 'package:indonesia_vocab/services/dictionary.dart';
import 'package:indonesia_vocab/services/progress_store.dart';
import 'package:indonesia_vocab/theme/palette.dart';

List<DictEntry> _words(int n) => [
      for (var i = 0; i < n; i++)
        DictEntry(
          word: 'kata$i',
          gloss: '词 $i',
          page: 0,
          level: 0,
        ),
    ];

Future<void> _pumpQuiz(WidgetTester tester, List<DictEntry> words, {bool isReview = false}) async {
  SharedPreferences.setMockInitialValues({});
  final store = ProgressStore();
  await store.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Palette.light, Brightness.light),
      home: WordQuizScreen(
        title: '测试',
        isReview: isReview,
        words: words,
        pool: words,
        store: store,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('选多少个词就测多少个：10 个', (tester) async {
    await _pumpQuiz(tester, _words(10));
    expect(find.textContaining('1/10'), findsWidgets);
    expect(find.textContaining('第 1 轮'), findsWidgets);
  });

  testWidgets('选多少个词就测多少个：3 个', (tester) async {
    await _pumpQuiz(tester, _words(3));
    expect(find.textContaining('1/3'), findsWidgets);
  });

  testWidgets('题目只出现本组内的词', (tester) async {
    await _pumpQuiz(tester, _words(5));
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(texts.contains('kata0') || texts.contains('kata1'), isTrue);
  });

  testWidgets('第一轮全部答对后能进入第二轮', (tester) async {
    await _pumpQuiz(tester, _words(3));

    for (var q = 0; q < 3; q++) {
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      final pattern = RegExp(r'^kata[0-9]+$');
      String shown = '';
      for (final t in texts) {
        if (pattern.hasMatch(t)) {
          shown = t;
          break;
        }
      }
      expect(shown, isNotEmpty, reason: '第 ${q + 1} 题没找到单词');
      final index = int.parse(shown.substring(4));

      await tester.tap(find.text('词 $index'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.textContaining(q == 2 ? '看结果' : '继续'));
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.textContaining('第 1 轮结束'), findsOneWidget);
    await tester.tap(find.textContaining('开始第 2 轮'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('第 2 轮'), findsWidgets);
    expect(find.textContaining('1/3'), findsWidgets);
  });
}

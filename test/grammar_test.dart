import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/screens/grammar_practice_screen.dart';
import 'package:indonesia_vocab/services/grammar_store.dart';
import 'package:indonesia_vocab/theme/palette.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('语法库能加载，条目和分类都不为空', () async {
    await GrammarStore.load();
    expect(GrammarStore.points.length, greaterThan(10));
    expect(GrammarStore.categories, isNotEmpty);
  });

  test('语法搜索独立于词库：能搜到，也能搜空', () async {
    await GrammarStore.load();
    expect(GrammarStore.search('被动'), isNotEmpty);
    expect(GrammarStore.search('akfsdf'), isEmpty);
    // 空查询返回全部，不设条数上限
    expect(GrammarStore.search('').length, GrammarStore.points.length);
  });

  test('大部分语法点带练习，且练习数据完整', () async {
    await GrammarStore.load();
    final withPractice =
        GrammarStore.points.where((g) => g.practice.isNotEmpty).length;
    expect(withPractice * 2, greaterThanOrEqualTo(GrammarStore.points.length));

    for (final g in GrammarStore.points) {
      for (final p in g.practice) {
        expect(p.options.length, greaterThanOrEqualTo(2), reason: g.id);
        expect(p.options.contains(p.answer), isTrue, reason: g.id);
        expect(p.why, isNotEmpty, reason: g.id);
      }
    }
  });

  testWidgets('练习答错会显示正确答案和解释', (tester) async {
    await GrammarStore.load();
    final point = GrammarStore.points.firstWhere((g) => g.practice.isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.light, Brightness.light),
        home: GrammarPracticeScreen(point: point),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final item = point.practice.first;
    final wrong = item.options.firstWhere((o) => o != item.answer);

    await tester.tap(find.text(wrong));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('正确答案是'), findsOneWidget);
    expect(find.text(item.why), findsOneWidget);
  });
}

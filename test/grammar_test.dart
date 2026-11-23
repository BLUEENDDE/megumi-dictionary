import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/screens/grammar_practice_screen.dart';
import 'package:indonesia_vocab/screens/grammar_history_screen.dart';
import 'package:indonesia_vocab/screens/grammar_screen.dart';
import 'package:indonesia_vocab/services/grammar_history.dart';
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

  test('语法归在《新编印尼语（语法）》下', () async {
    await GrammarStore.load();
    for (final g in GrammarStore.points) {
      expect(g.book, '新编印尼语（语法）', reason: g.id);
    }
  });

  test('换一批会换到不同的语法', () async {
    await GrammarStore.load();
    GrammarStore.resetRotation();
    final a = GrammarStore.shuffleBatch().map((g) => g.id).toList();
    final b = GrammarStore.shuffleBatch().map((g) => g.id).toList();
    expect(a.length, greaterThan(0));
    expect(a.join(',') == b.join(','), isFalse);
  });

  test('相关语法的 id 都能解析到条目', () async {
    await GrammarStore.load();
    for (final g in GrammarStore.points) {
      for (final id in g.related) {
        expect(GrammarStore.byId(id), isNotNull, reason: '${g.id} → $id');
      }
    }
  });

  testWidgets('语法页有换一批按钮，点了会换内容', (tester) async {
    await GrammarStore.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.light, Brightness.light),
        home: const GrammarScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final first = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((t) => t.length > 4)
        .join('|');

    expect(find.text('换一批'), findsOneWidget);
    await tester.tap(find.text('换一批'));
    await tester.pump(const Duration(milliseconds: 300));

    final second = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((t) => t.length > 4)
        .join('|');

    expect(second, isNot(equals(first)));
  });

  test('浏览历史最近优先、去重、上限 20 条', () async {
    SharedPreferences.setMockInitialValues({});
    await GrammarHistory.clear();

    await GrammarHistory.add('a');
    await GrammarHistory.add('b');
    await GrammarHistory.add('a'); // 再看一次，应移到最前

    expect(GrammarHistory.ids.take(2).toList(), ['a', 'b']);

    for (var i = 0; i < 25; i++) {
      await GrammarHistory.add('x$i');
    }
    expect(GrammarHistory.ids.length, GrammarHistory.maxCount);
    expect(GrammarHistory.ids.first, 'x24');
  });

  test('浏览历史在重启后仍在（写入本地存储）', () async {
    SharedPreferences.setMockInitialValues({});
    await GrammarHistory.clear();
    await GrammarHistory.add('vault-02');

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('grammar_history_v1');
    expect(saved, isNotNull);
    expect(saved!.first, 'vault-02');
  });

  test('句型单独成类，多数带例句', () async {
    await GrammarStore.load();
    final patterns =
        GrammarStore.points.where((g) => g.cat == '句型').toList();

    expect(patterns.length, greaterThanOrEqualTo(10));
    final withExample = patterns.where((g) => g.examples.isNotEmpty).length;
    expect(withExample, greaterThanOrEqualTo(10));

    for (final g in patterns) {
      expect(g.title.contains('基本句型数据库'), isFalse);
    }
    expect(patterns.any((g) => g.title.contains('S + P + O')), isTrue);
  });

  testWidgets('最近浏览是入口，点进去按分类分组显示', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await GrammarStore.load();
    await GrammarHistory.clear();

    // 造两条不同分类的记录
    final a = GrammarStore.points.firstWhere((g) => g.cat == '词缀');
    final b = GrammarStore.points.firstWhere((g) => g.cat == '句型');
    await GrammarHistory.add(a.id);
    await GrammarHistory.add(b.id);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.light, Brightness.light),
        home: const GrammarHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.textContaining('词缀 · '), findsOneWidget);
    expect(find.textContaining('句型 · '), findsOneWidget);
    expect(find.text(a.title), findsOneWidget);
    expect(find.text(b.title), findsOneWidget);
  });
}

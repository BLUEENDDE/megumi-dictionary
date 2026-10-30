import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/models/word_pair.dart';
import 'package:indonesia_vocab/screens/home_screen.dart';
import 'package:indonesia_vocab/services/progress_store.dart';
import 'package:indonesia_vocab/services/settings_store.dart';
import 'package:indonesia_vocab/services/user_pairs_store.dart';
import 'package:indonesia_vocab/theme/palette.dart';

Widget _app(HomeScreen home) => MaterialApp(
      theme: buildTheme(Palette.light, Brightness.light),
      home: home,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.wordList.value = 'beginner';
  });

  tearDown(() {
    SettingsStore.wordList.value = 'beginner';
  });

  testWidgets('首页显示总卡：复习 / 新学 两个入口', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        HomeScreen(
          progress: ProgressStore(),
          userPairs: UserPairsStore(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('背词'), findsOneWidget);
    expect(find.text('复习'), findsOneWidget);
    expect(find.text('新学'), findsOneWidget);
    expect(find.text('选择词单'), findsOneWidget);
  });

  testWidgets('自建词库里的词会出现在首页词表里', (WidgetTester tester) async {
    final store = UserPairsStore();
    await store.load();
    await store.add(
      WordPair(
        id: 'user-1',
        tag: '导入',
        summary: '',
        first: const WordSense(form: 'makan', gloss: '吃'),
        second: const WordSense(form: '', gloss: ''),
        axes: const [],
        example: const ExamplePair(
          firstText: '',
          firstGloss: '',
          firstNote: '',
          secondText: '',
          secondGloss: '',
          secondNote: '',
        ),
      ),
    );

    SettingsStore.wordList.value = 'user';

    await tester.pumpWidget(
      _app(
        HomeScreen(
          progress: ProgressStore(),
          userPairs: store,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('makan'), findsOneWidget);
    expect(find.text('吃'), findsOneWidget);
    expect(find.text('词条'), findsOneWidget);
  });
}

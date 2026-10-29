import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/screens/home_screen.dart';
import 'package:indonesia_vocab/services/progress_store.dart';
import 'package:indonesia_vocab/services/user_pairs_store.dart';
import 'package:indonesia_vocab/theme/palette.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页显示总卡：复习 / 新学 两个入口', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.light, Brightness.light),
        home: HomeScreen(
          pairs: const [],
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页能渲染，没学过时给的是「学新词对」', (WidgetTester tester) async {
    await tester.pumpWidget(const VocabApp());
    await tester.pumpAndSettle();

    expect(find.text('背词'), findsOneWidget);
    // 一组都没学过，所以不该出现"开始复习"，而是引导去学
    expect(find.text('学新词对'), findsOneWidget);
    expect(find.text('开始复习'), findsNothing);
    expect(find.text('besar'), findsWidgets);
    expect(find.text('luas'), findsWidgets);
    expect(find.text('还没练过'), findsWidgets);
  });
}

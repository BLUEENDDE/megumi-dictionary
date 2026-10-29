import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页能渲染，主按钮叫「开始复习」', (WidgetTester tester) async {
    await tester.pumpWidget(const VocabApp());
    await tester.pumpAndSettle();

    // 「背词」既是标题也是底部页签，所以是多处
    expect(find.text('背词'), findsWidgets);
    // 学习和复习共用一个按钮
    expect(find.text('开始复习'), findsOneWidget);
    expect(find.text('besar'), findsWidgets);
    expect(find.text('luas'), findsWidgets);
    expect(find.text('还没练过'), findsWidgets);
  });
}

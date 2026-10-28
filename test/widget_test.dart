import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/main.dart';

void main() {
  testWidgets('首页能渲染，并列出词对', (WidgetTester tester) async {
    await tester.pumpWidget(const VocabApp());
    await tester.pumpAndSettle();

    expect(find.text('易混词'), findsOneWidget);
    expect(find.text('开始复习'), findsOneWidget);
    expect(find.text('besar'), findsWidgets);
    expect(find.text('luas'), findsWidgets);
  });
}

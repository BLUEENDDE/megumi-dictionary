import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页只显示总卡，词对要等点新学才出现', (WidgetTester tester) async {
    await tester.pumpWidget(const VocabApp());
    await tester.pumpAndSettle();

    // 「背词」既是标题也是底部页签，所以是多处
    expect(find.text('背词'), findsWidgets);
    expect(find.text('复习'), findsOneWidget);
    expect(find.text('新学'), findsOneWidget);

    // 没点新学之前，词对不出现在列表里
    expect(find.text('还没练过'), findsNothing);
    expect(find.text('词对'), findsNothing);

    await tester.tap(find.text('新学'));
    await tester.pumpAndSettle();

    // 词对在列表下方，先滚上去（ListView 懒加载）
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    // 点完之后才出现词对
    expect(find.text('词对'), findsOneWidget);
    expect(find.text('还没练过'), findsWidgets);
  });
}

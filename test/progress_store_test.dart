import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/services/progress_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('记录后能重新读出来', () async {
    final store = ProgressStore();
    await store.load();

    expect(store.statFor('besar-luas').untrained, isTrue);

    await store.record('besar-luas', true);
    await store.record('besar-luas', false);

    expect(store.statFor('besar-luas').seen, 2);
    expect(store.statFor('besar-luas').right, 1);
    expect(store.statFor('besar-luas').accuracyPercent, 50);
    expect(store.todayCount, 2);

    // 模拟重开 App
    final reopened = ProgressStore();
    await reopened.load();

    expect(reopened.statFor('besar-luas').seen, 2);
    expect(reopened.statFor('besar-luas').accuracyPercent, 50);
    expect(reopened.trainedPairs, 1);
    expect(reopened.overallAccuracy, 50);
  });

  test('重置后清空', () async {
    final store = ProgressStore();
    await store.load();
    await store.record('a', true);

    await store.reset();

    expect(store.statFor('a').untrained, isTrue);
    expect(store.todayCount, 0);
  });
}

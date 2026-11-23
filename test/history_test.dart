import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/services/history_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('最多记 20 条，满了不再记录新词', () async {
    final store = HistoryStore.instance;
    await store.load();
    await store.clear();

    for (var i = 0; i < 25; i++) {
      await store.add('kata$i');
    }

    expect(store.length, HistoryStore.maxItems);
    // 最新的是 kata19，最早的是 kata0
    expect(store.words.first, 'kata19');
    expect(store.words.contains('kata24'), isFalse);
  });

  test('重复看同一个词只挪到最前，不占新名额', () async {
    final store = HistoryStore.instance;
    await store.load();
    await store.clear();

    await store.add('a');
    await store.add('b');
    await store.add('c');
    await store.add('a');

    expect(store.words.take(3).toList(), ['a', 'c', 'b']);
    expect(store.length, 3);
  });

  test('写盘后能读回', () async {
    final store = HistoryStore.instance;
    await store.load();
    await store.clear();
    await store.add('tanah');
    await store.add('rumah');

    final again = HistoryStore.instance;
    await again.load();
    expect(again.words.contains('tanah'), isTrue);
  });
}

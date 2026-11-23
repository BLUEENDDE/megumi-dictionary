import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/services/history_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('看多少记多少，不设上限', () async {
    final store = HistoryStore.instance;
    await store.load();
    await store.clear();

    for (var i = 0; i < 60; i++) {
      await store.add('kata$i');
    }

    expect(store.length, 60);
    expect(store.words.first, 'kata59');
    expect(store.words.last, 'kata0');
  });

  test('重复看同一个词只挪到最前', () async {
    final store = HistoryStore.instance;
    await store.load();
    await store.clear();

    await store.add('a');
    await store.add('b');
    await store.add('a');

    expect(store.words, ['a', 'b']);
  });

  test('写盘后能读回', () async {
    final store = HistoryStore.instance;
    await store.load();
    await store.clear();
    await store.add('tanah');

    final again = HistoryStore.instance;
    await again.load();
    expect(again.words, contains('tanah'));
  });
}
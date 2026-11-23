import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/services/grammar_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('换一批：批内不重复，连续两批不重叠', () async {
    await GrammarStore.load();
    GrammarStore.resetRotation();

    final first = GrammarStore.shuffleBatch(count: 8);
    final second = GrammarStore.shuffleBatch(count: 8);

    expect(first.length, 8);
    expect(first.map((g) => g.id).toSet().length, first.length, reason: '批内有重复');
    expect(
      first.map((g) => g.id).toSet().intersection(second.map((g) => g.id).toSet()).isEmpty,
      isTrue,
      reason: '两批之间重复了',
    );
  });

  test('当前批是静态保存的，重建页面也不会换', () async {
    await GrammarStore.load();
    GrammarStore.resetRotation();

    final batch = GrammarStore.shuffleBatch(count: 6);
    final again = GrammarStore.currentBatch;

    expect(again.map((g) => g.id).toList(), batch.map((g) => g.id).toList());
  });
}
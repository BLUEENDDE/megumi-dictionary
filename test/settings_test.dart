import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/services/settings_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.learnBatch.value = SettingsStore.defaultBatch;
  });

  test('批量默认 20，改完能读回来', () async {
    final store = SettingsStore();
    await store.load();
    expect(SettingsStore.learnBatch.value, 20);

    await store.setLearnBatch(5);

    final reopened = SettingsStore();
    await reopened.load();
    expect(SettingsStore.learnBatch.value, 5);
  });

  test('存了个非法值就回到默认', () async {
    SharedPreferences.setMockInitialValues({'learn_batch': 37});
    final store = SettingsStore();
    await store.load();
    expect(SettingsStore.learnBatch.value, SettingsStore.defaultBatch);
  });

  test('可选项是 5 / 15 / 20', () {
    expect(SettingsStore.batchOptions, [5, 15, 20]);
    expect(SettingsStore.batchOptions.contains(SettingsStore.defaultBatch), isTrue);
  });

  test('按词数换算成词对组数（一组两个词）', () {
    expect(SettingsStore.pairsForWords(5), 3); // 5 个词 → 3 组（6 个词）
    expect(SettingsStore.pairsForWords(15), 8);
    expect(SettingsStore.pairsForWords(20), 10);
    expect(SettingsStore.pairsForWords(2), 1);
  });

  test('备份时间会记住', () async {
    SettingsStore.lastBackupAt.value = null;
    final store = SettingsStore();
    await store.load();
    expect(SettingsStore.lastBackupAt.value, isNull);

    await store.markBackedUp();

    final reopened = SettingsStore();
    await reopened.load();
    expect(SettingsStore.lastBackupAt.value, isNotNull);
    expect(
      SettingsStore.lastBackupAt.value,
      greaterThan(DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch),
    );
  });
}

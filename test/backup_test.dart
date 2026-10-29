import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/models/word_pair.dart';
import 'package:indonesia_vocab/services/backup_service.dart';
import 'package:indonesia_vocab/services/progress_store.dart';

const _pair = WordPair(
  id: 'user-9',
  tag: '尺寸',
  summary: '体积 vs 面积',
  first: WordSense(form: 'besar', gloss: '大（体积）'),
  second: WordSense(form: 'luas', gloss: '大（面积）'),
  axes: [ContrastAxis(name: '对象', first: '体积', second: '面积')],
  example: ExamplePair(
    firstText: 'Rumah itu besar.',
    firstGloss: '房子很大。',
    firstNote: '建筑',
    secondText: 'Lapangan itu luas.',
    secondGloss: '操场很大。',
    secondNote: '场地',
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('导出再导入，词对和进度都对得上', () async {
    final store = ProgressStore();
    await store.load();
    await store.record('user-9', true);

    final text = BackupService.encode(userPairs: [_pair], progress: store);
    expect(text.contains('indonesia_vocab'), isTrue);

    final data = BackupService.decode(text);
    expect(data.userPairs.length, 1);
    expect(data.userPairs.first.first.form, 'besar');
    expect(data.userPairs.first.axes.single.name, '对象');

    final restored = ProgressStore();
    await restored.load();
    restored.loadFromMap(data.progress);
    expect(restored.statFor('user-9').seen, 1);
    expect(restored.statFor('user-9').box, 1);
  });

  test('乱七八糟的文本会报错而不是崩掉', () {
    expect(
      () => BackupService.decode('这不是 json'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => BackupService.decode('{"app":"other"}'),
      throwsA(isA<FormatException>()),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:indonesia_vocab/models/word_pair.dart';
import 'package:indonesia_vocab/services/user_pairs_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('自建词对能存能读，字段不丢', () async {
    final store = UserPairsStore();
    await store.load();
    expect(store.pairs, isEmpty);

    const pair = WordPair(
      id: 'user-1',
      tag: '尺寸',
      summary: '体积 vs 面积',
      first: WordSense(form: 'besar', gloss: '大（体积）'),
      second: WordSense(form: 'luas', gloss: '大（面积）'),
      axes: [
        ContrastAxis(name: '适用对象', first: '体积', second: '面积'),
      ],
      example: ExamplePair(
        firstText: 'Rumah itu besar.',
        firstGloss: '那房子很大。',
        firstNote: '建筑',
        secondText: 'Lapangan itu luas.',
        secondGloss: '那操场很大。',
        secondNote: '场地',
      ),
    );

    await store.add(pair);

    final reopened = UserPairsStore();
    await reopened.load();

    expect(reopened.pairs.length, 1);
    final loaded = reopened.pairs.first;
    expect(loaded.id, 'user-1');
    expect(loaded.isUserMade, isTrue);
    expect(loaded.first.form, 'besar');
    expect(loaded.second.gloss, '大（面积）');
    expect(loaded.axes.single.name, '适用对象');
    expect(loaded.example.secondText, 'Lapangan itu luas.');
  });

  test('删除后不再出现', () async {
    final store = UserPairsStore();
    await store.load();

    const pair = WordPair(
      id: 'user-2',
      tag: '',
      summary: 's',
      first: WordSense(form: 'a', gloss: ''),
      second: WordSense(form: 'b', gloss: ''),
      axes: [],
      example: ExamplePair(
        firstText: '',
        firstGloss: '',
        firstNote: '',
        secondText: '',
        secondGloss: '',
        secondNote: '',
      ),
    );

    await store.add(pair);
    expect(store.pairs.length, 1);

    await store.remove('user-2');
    expect(store.pairs, isEmpty);
  });
}

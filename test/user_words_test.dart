import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/models/word_pair.dart';
import 'package:indonesia_vocab/services/user_words.dart';

WordPair _pair({
  String first = '',
  String firstGloss = '',
  String second = '',
  String secondGloss = '',
  String id = 'user-1',
}) =>
    WordPair(
      id: id,
      tag: '导入',
      summary: '',
      first: WordSense(form: first, gloss: firstGloss),
      second: WordSense(form: second, gloss: secondGloss),
      axes: const [],
      example: const ExamplePair(
        firstText: '',
        firstGloss: '',
        firstNote: '',
        secondText: '',
        secondGloss: '',
        secondNote: '',
      ),
    );

void main() {
  test('一组词对里的两个词都会变成可背的词条', () {
    final entries = dictEntriesFromPairs([
      _pair(first: 'besar', firstGloss: '大（体积）', second: 'luas', secondGloss: '大（面积）'),
    ]);

    expect(entries.map((e) => e.word), ['besar', 'luas']);
    expect(entries.map((e) => e.gloss), ['大（体积）', '大（面积）']);
    expect(entries.every((e) => e.level == userWordLevel), isTrue);
    expect(entries.first.level, -1);
  });

  test('只录了一个词（第二个为空）时只产出一个词条', () {
    final entries = dictEntriesFromPairs([_pair(first: 'makan', firstGloss: '吃')]);
    expect(entries.length, 1);
    expect(entries.single.word, 'makan');
  });

  test('同一个词重复录只保留第一次', () {
    final entries = dictEntriesFromPairs([
      _pair(first: 'makan', firstGloss: '吃', id: 'user-1'),
      _pair(first: 'Makan', firstGloss: '吃饭', id: 'user-2'),
    ]);
    expect(entries.length, 1);
    expect(entries.single.gloss, '吃');
  });

  test('词前后空格会被去掉，没写释义给占位', () {
    final entries = dictEntriesFromPairs([
      _pair(first: '  tidur  ', firstGloss: '  '),
    ]);
    expect(entries.single.word, 'tidur');
    expect(entries.single.gloss, '（还没写释义）');
  });

  test('词为空的词对不会变成空词条', () {
    expect(dictEntriesFromPairs([_pair()]), isEmpty);
  });
}

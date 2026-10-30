import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/screens/word_quiz_screen.dart';
import 'package:indonesia_vocab/services/dictionary.dart';

DictEntry _e(String word, String gloss) =>
    DictEntry(word: word, gloss: gloss, page: 0);

void main() {
  test('同一题里不会出现两个一样的释义', () {
    // 前三个词共用「甲」，如果不去重，正确项旁边还会站一个「甲」。
    final pool = [
      _e('a', '甲'),
      _e('b', '甲'),
      _e('c', '甲'),
      _e('d', '乙'),
      _e('e', '丙'),
      _e('f', '丁'),
    ];

    final q = buildWordQuestions(
      words: [_e('a', '甲')],
      pool: pool,
      random: Random(7),
    ).single;

    final glosses = q.options.map((o) => o.gloss).toList();
    expect(glosses.length, 4);
    expect(glosses.toSet().length, glosses.length);
  });

  test('答案永远在选项里，且只出现一次', () {
    final pool = [for (var i = 0; i < 30; i++) _e('w$i', 'g$i')];
    final words = [for (var i = 0; i < 10; i++) _e('w$i', 'g$i')];

    for (var seed = 0; seed < 20; seed++) {
      final questions = buildWordQuestions(
        words: words,
        pool: pool,
        random: Random(seed),
      );
      expect(questions.length, words.length);
      for (final q in questions) {
        expect(q.options.where((o) => o.word == q.answer.word).length, 1);
      }
    }
  });

  test('词池为空不会崩，至少保留正确答案', () {
    final q = buildWordQuestions(
      words: [_e('a', '甲')],
      pool: const [],
      random: Random(1),
    ).single;
    expect(q.options.single.word, 'a');
  });

  test('词池太小就少给选项，不抛异常', () {
    final questions = buildWordQuestions(
      words: [_e('a', '甲'), _e('b', '乙')],
      pool: [_e('a', '甲'), _e('b', '乙')],
      random: Random(1),
    );
    expect(questions.length, 2);
    expect(questions.every((q) => q.options.length <= 2), isTrue);
  });

  test('空词表返回空题目', () {
    expect(
      buildWordQuestions(words: const [], pool: [_e('a', '甲')]),
      isEmpty,
    );
  });

  test('没有释义的干扰项会被跳过', () {
    final pool = [
      _e('a', '甲'),
      _e('blank1', ''),
      _e('blank2', '  '),
      _e('b', '乙'),
      _e('c', '丙'),
      _e('d', '丁'),
    ];
    final q = buildWordQuestions(
      words: [_e('a', '甲')],
      pool: pool,
      random: Random(3),
    ).single;
    expect(q.options.every((o) => o.gloss.trim().isNotEmpty), isTrue);
  });
}

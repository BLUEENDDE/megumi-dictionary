import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/services/word_text_import.dart';

void main() {
  test('竖线分隔，正常解析', () {
    final r = parseWordList('besar | 大（体积） | luas | 大（面积） | 体积 vs 面积');
    expect(r.errors, isEmpty);
    expect(r.drafts.length, 1);
    expect(r.drafts.first.first, 'besar');
    expect(r.drafts.first.secondGloss, '大（面积）');
    expect(r.drafts.first.summary, '体积 vs 面积');
  });

  test('逗号、制表符、全角竖线都能用', () {
    final r = parseWordList(
      'melihat,看见,menonton,观看\n'
      'senang\t高兴\tbahagia\t幸福\n'
      'cepat｜快｜lekas｜尽快',
    );
    expect(r.drafts.length, 3);
    expect(r.drafts[1].first, 'senang');
    expect(r.drafts[2].second, 'lekas');
  });

  test('空行和注释被跳过', () {
    final r = parseWordList(
      '# 这是注释\n\n'
      'a | 甲 | b | 乙\n',
    );
    expect(r.drafts.length, 1);
    expect(r.errors, isEmpty);
  });

  test('段数不够会报错并带行号', () {
    final r = parseWordList('a | 甲 | b\n');
    expect(r.drafts, isEmpty);
    expect(r.errors.single, contains('第 1 行'));
  });

  test('缺摘要时自动生成占位', () {
    final r = parseWordList('a | 甲 | b | 乙');
    expect(r.drafts.single.summary, 'a 和 b 的区别（待补充）');
  });

  test('缺释义时给占位而不是崩', () {
    final r = parseWordList('a |  | b | 乙');
    expect(r.drafts.single.firstGloss, '（还没写释义）');
  });
}

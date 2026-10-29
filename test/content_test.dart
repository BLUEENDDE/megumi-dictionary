import 'package:flutter_test/flutter_test.dart';

import 'package:indonesia_vocab/data/sample_data.dart';
import 'package:indonesia_vocab/data/word_families.dart';

/// 印尼语的鼻音同化会让词根首辅音脱落或变化（tulis → menulis、tanya → penanya），
/// 所以判断归属时允许"去掉词根首字母"也算同族。
void main() {
  test('每个词族都有词根、释义和至少两个派生词', () {
    expect(wordFamilies, isNotEmpty);
    for (final family in wordFamilies) {
      expect(family.root.trim(), isNotEmpty);
      expect(family.rootGloss.trim(), isNotEmpty);
      expect(family.rootNote.trim(), isNotEmpty);
      expect(
        family.members.length,
        greaterThanOrEqualTo(2),
        reason: '${family.root} 的派生词太少',
      );

      for (final member in family.members) {
        expect(member.form.trim(), isNotEmpty);
        expect(member.affix.trim(), isNotEmpty);
        expect(member.gloss.trim(), isNotEmpty);

        final root = family.root.toLowerCase();
        final form = member.form.toLowerCase();
        final belongs =
            form.contains(root) || form.contains(root.substring(1));
        expect(
          belongs,
          isTrue,
          reason: '${member.form} 不含词根 ${family.root}',
        );
      }
    }
  });

  test('词对数据的例句里含目标词，否则出不了题', () {
    for (final pair in samplePairs) {
      expect(
        pair.example.firstText.toLowerCase().contains(pair.first.form.toLowerCase()),
        isTrue,
        reason: '${pair.first.form} 的例句不含该词',
      );
      expect(
        pair.example.secondText
            .toLowerCase()
            .contains(pair.second.form.toLowerCase()),
        isTrue,
        reason: '${pair.second.form} 的例句不含该词',
      );
    }
  });
}

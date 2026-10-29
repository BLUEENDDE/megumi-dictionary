import '../data/word_families.dart';
import '../models/word_family.dart';

/// 给一个词找它的词族。
///
/// 先精确匹配词根或派生词，找不到再退一步用"词形包含词根"兜底
/// （比如例句里出现 mengambil，也该能回到 ambil 那一族）。
WordFamily? familyForWord(String word) {
  final w = word.trim().toLowerCase();
  if (w.isEmpty) return null;

  for (final family in wordFamilies) {
    if (family.root.toLowerCase() == w) return family;
  }

  for (final family in wordFamilies) {
    for (final member in family.members) {
      if (member.form.toLowerCase() == w) return family;
    }
  }

  for (final family in wordFamilies) {
    if (w.contains(family.root.toLowerCase())) return family;
  }

  return null;
}

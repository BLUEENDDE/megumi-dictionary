import '../models/word_pair.dart';
import 'dictionary.dart' show DictEntry;

/// 自建词条在界面上的级别标记：-1 表示"自己加的"，显示为「自」。
const int userWordLevel = -1;

/// 把用户自建的词对拆成可以背的单词条目。
///
/// 一组词对里最多两个词，各算一个词条；空的第二个词（只录了一个词时）会被跳过。
/// 同一个词重复出现只保留第一次，避免测验里同一题出现两个一样的答案。
List<DictEntry> dictEntriesFromPairs(Iterable<WordPair> pairs) {
  final out = <DictEntry>[];
  final seen = <String>{};

  for (final pair in pairs) {
    _add(
      out,
      seen,
      form: pair.first.form,
      gloss: pair.first.gloss,
      example: pair.example.firstText,
      exampleCn: pair.example.firstGloss,
    );
    _add(
      out,
      seen,
      form: pair.second.form,
      gloss: pair.second.gloss,
      example: pair.example.secondText,
      exampleCn: pair.example.secondGloss,
    );
  }

  return out;
}

void _add(
  List<DictEntry> out,
  Set<String> seen, {
  required String form,
  required String gloss,
  required String example,
  required String exampleCn,
}) {
  final word = form.trim();
  if (word.isEmpty) return;
  if (!seen.add(word.toLowerCase())) return;

  final meaning = gloss.trim();
  out.add(
    DictEntry(
      word: word,
      gloss: meaning.isEmpty ? '（还没写释义）' : meaning,
      page: 0,
      level: userWordLevel,
      example: example.trim(),
      exampleCn: exampleCn.trim(),
    ),
  );
}

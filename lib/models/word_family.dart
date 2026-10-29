/// 词族：一个词根 + 它派生出来的一串词。
library;

class DerivedWord {
  final String form;

  /// 词缀，例如 meN-、di-、peN-...-an
  final String affix;

  /// 中文意思
  final String gloss;

  /// 这个词缀带来的作用
  final String note;

  const DerivedWord({
    required this.form,
    required this.affix,
    required this.gloss,
    required this.note,
  });
}

class WordFamily {
  final String root;

  /// 词根的意思
  final String rootGloss;

  /// 词根的性质（动词/名词/形容词）与说明
  final String rootNote;

  final List<DerivedWord> members;

  const WordFamily({
    required this.root,
    required this.rootGloss,
    required this.rootNote,
    required this.members,
  });
}

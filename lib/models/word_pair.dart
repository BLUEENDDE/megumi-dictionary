/// 数据模型：一组易混词 + 差异板块 + 最小对比句。
library;

/// 一个词的一个义项。
class WordSense {
  final String form;
  final String gloss;

  const WordSense({required this.form, required this.gloss});
}

/// 一个差异板块（一条对比轴）。
class ContrastAxis {
  final String name;
  final String first;
  final String second;

  const ContrastAxis({
    required this.name,
    required this.first,
    required this.second,
  });
}

/// 一对最小对比句。
class ExamplePair {
  final String firstText;
  final String firstGloss;
  final String firstNote;
  final String secondText;
  final String secondGloss;
  final String secondNote;

  const ExamplePair({
    required this.firstText,
    required this.firstGloss,
    required this.firstNote,
    required this.secondText,
    required this.secondGloss,
    required this.secondNote,
  });
}

/// 一组词对：两个词、若干板块、一对例句。
class WordPair {
  final String id;
  final String tag;
  final String summary;
  final WordSense first;
  final WordSense second;
  final List<ContrastAxis> axes;
  final ExamplePair example;

  const WordPair({
    required this.id,
    required this.tag,
    required this.summary,
    required this.first,
    required this.second,
    required this.axes,
    required this.example,
  });
}

/// 复习时的一道题。
class QuizItem {
  final WordPair pair;
  final String prompt;
  final String gloss;
  final String answer;
  final List<String> options;
  final String note;

  const QuizItem({
    required this.pair,
    required this.prompt,
    required this.gloss,
    required this.answer,
    required this.options,
    required this.note,
  });
}

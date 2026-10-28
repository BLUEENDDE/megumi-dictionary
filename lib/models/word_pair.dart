/// 数据模型：一组易混词 + 差异板块 + 最小对比句。
library;

/// 一个词的一个义项。
class WordSense {
  final String form;
  final String gloss;

  const WordSense({required this.form, required this.gloss});

  Map<String, dynamic> toJson() => {'form': form, 'gloss': gloss};

  factory WordSense.fromJson(Map<String, dynamic> json) => WordSense(
        form: json['form'] as String? ?? '',
        gloss: json['gloss'] as String? ?? '',
      );
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'first': first,
        'second': second,
      };

  factory ContrastAxis.fromJson(Map<String, dynamic> json) => ContrastAxis(
        name: json['name'] as String? ?? '',
        first: json['first'] as String? ?? '',
        second: json['second'] as String? ?? '',
      );
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

  Map<String, dynamic> toJson() => {
        'firstText': firstText,
        'firstGloss': firstGloss,
        'firstNote': firstNote,
        'secondText': secondText,
        'secondGloss': secondGloss,
        'secondNote': secondNote,
      };

  factory ExamplePair.fromJson(Map<String, dynamic> json) => ExamplePair(
        firstText: json['firstText'] as String? ?? '',
        firstGloss: json['firstGloss'] as String? ?? '',
        firstNote: json['firstNote'] as String? ?? '',
        secondText: json['secondText'] as String? ?? '',
        secondGloss: json['secondGloss'] as String? ?? '',
        secondNote: json['secondNote'] as String? ?? '',
      );
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

  /// 用户自己加的词对，id 以 user- 开头。
  bool get isUserMade => id.startsWith('user-');

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'summary': summary,
        'first': first.toJson(),
        'second': second.toJson(),
        'axes': axes.map((a) => a.toJson()).toList(),
        'example': example.toJson(),
      };

  factory WordPair.fromJson(Map<String, dynamic> json) => WordPair(
        id: json['id'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        first: WordSense.fromJson(
          (json['first'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        second: WordSense.fromJson(
          (json['second'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        axes: ((json['axes'] as List?) ?? [])
            .map(
              (e) => ContrastAxis.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList(),
        example: ExamplePair.fromJson(
          (json['example'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
      );
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

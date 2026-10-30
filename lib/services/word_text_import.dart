/// 文本批量导入：一行一个词，或者一行一组易混词对。
///
/// 一行两段：词、释义。
/// 一行四段：词A、A 的释义、词B、B 的释义；第 5 段是"差在哪"（可空）。
/// 支持的分隔符：竖线 `|`、全角竖线 `｜`、制表符、逗号 `,`、全角逗号 `，`。
/// 以 # 开头的行是注释，会被忽略。
library;

class WordDraft {
  final String first;
  final String firstGloss;
  final String second;
  final String secondGloss;
  final String summary;

  const WordDraft({
    required this.first,
    required this.firstGloss,
    required this.second,
    required this.secondGloss,
    required this.summary,
  });
}

class ImportParseResult {
  final List<WordDraft> drafts;
  final List<String> errors;

  const ImportParseResult({required this.drafts, required this.errors});

  bool get isEmpty => drafts.isEmpty;
}

ImportParseResult parseWordList(String raw) {
  final drafts = <WordDraft>[];
  final errors = <String>[];
  final lines = raw.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final parts = _split(line);
    if (parts.length < 2 || parts.length == 3) {
      errors.add(
        '第 ${i + 1} 行：写成「词 | 释义」，或「词A | 释义A | 词B | 释义B」',
      );
      continue;
    }

    final first = parts[0];
    final second = parts.length >= 4 ? parts[2] : '';
    if (first.isEmpty) {
      errors.add('第 ${i + 1} 行：词不能为空');
      continue;
    }
    if (parts.length >= 4 && second.isEmpty) {
      errors.add('第 ${i + 1} 行：第二个词不能为空');
      continue;
    }

    drafts.add(
      WordDraft(
        first: first,
        firstGloss: parts[1].isEmpty ? '（还没写释义）' : parts[1],
        second: second,
        secondGloss: second.isEmpty
            ? ''
            : (parts[3].isEmpty ? '（还没写释义）' : parts[3]),
        summary: parts.length >= 5 && parts[4].isNotEmpty
            ? parts[4]
            : second.isEmpty
                ? first
                : '$first 和 $second 的区别（待补充）',
      ),
    );
  }

  return ImportParseResult(drafts: drafts, errors: errors);
}

List<String> _split(String line) {
  if (line.contains('|')) {
    return line.split('|').map((e) => e.trim()).toList();
  }
  if (line.contains('｜')) {
    return line.split('｜').map((e) => e.trim()).toList();
  }
  if (line.contains('\t')) {
    return line.split('\t').map((e) => e.trim()).toList();
  }
  if (line.contains('，')) {
    return line.split('，').map((e) => e.trim()).toList();
  }
  return line.split(',').map((e) => e.trim()).toList();
}

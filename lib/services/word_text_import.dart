/// 文本批量导入：一行一组词对。
///
/// 支持的分隔符：竖线 `|`、全角竖线 `｜`、制表符、逗号 `,`、全角逗号 `，`。
/// 每行至少 4 段：词A、A 的释义、词B、B 的释义；第 5 段是"差在哪"（可空）。
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
    if (parts.length < 4) {
      errors.add('第 ${i + 1} 行：至少要 4 段（词A | 释义A | 词B | 释义B）');
      continue;
    }

    final first = parts[0];
    final second = parts[2];
    if (first.isEmpty || second.isEmpty) {
      errors.add('第 ${i + 1} 行：两个词不能为空');
      continue;
    }

    drafts.add(
      WordDraft(
        first: first,
        firstGloss: parts[1].isEmpty ? '（还没写释义）' : parts[1],
        second: second,
        secondGloss: parts[3].isEmpty ? '（还没写释义）' : parts[3],
        summary: parts.length >= 5 && parts[4].isNotEmpty
            ? parts[4]
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

import 'dart:convert';

import '../models/word_pair.dart';
import 'progress_store.dart';

/// 备份/恢复：一份 JSON 文本，包含自建词对和学习进度。
class BackupService {
  static const version = 1;

  static String encode({
    required List<WordPair> userPairs,
    required ProgressStore progress,
  }) {
    final data = <String, dynamic>{
      'app': 'indonesia_vocab',
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'userPairs': userPairs.map((p) => p.toJson()).toList(),
      'progress': progress.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 解析备份。失败时抛 FormatException。
  static BackupData decode(String raw) {
    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('不是合法的 JSON');
    }
    if (parsed is! Map) {
      throw const FormatException('备份格式不对：顶层应该是对象');
    }
    final map = parsed.cast<String, dynamic>();
    if (map['app'] != 'indonesia_vocab') {
      throw const FormatException('这不像本 App 的备份文件');
    }

    final pairsJson = map['userPairs'];
    final pairs = <WordPair>[];
    if (pairsJson is List) {
      for (final item in pairsJson) {
        if (item is Map) {
          pairs.add(WordPair.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    final progressJson = map['progress'];
    return BackupData(
      userPairs: pairs,
      progress: progressJson is Map
          ? progressJson.cast<String, dynamic>()
          : <String, dynamic>{},
    );
  }
}

class BackupData {
  final List<WordPair> userPairs;
  final Map<String, dynamic> progress;

  const BackupData({required this.userPairs, required this.progress});
}

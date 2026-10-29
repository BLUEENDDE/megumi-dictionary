import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_pair.dart';

/// 一组词的练习记录 + 记忆调度状态。
class PairStat {
  final int seen;
  final int right;

  /// 记忆盒子：0 = 刚错/没记牢，越大越熟。
  final int box;

  /// 下次该复习的时间（毫秒时间戳），null 表示还没练过。
  final int? dueAt;

  const PairStat({
    this.seen = 0,
    this.right = 0,
    this.box = 0,
    this.dueAt,
  });

  bool get untrained => seen == 0;

  /// 学过至少一次。没学过的词不进复习队列。
  bool get learned => seen > 0;

  double get accuracy => seen == 0 ? 0 : right / seen;

  int get accuracyPercent => (accuracy * 100).round();

  /// 已学过、且到了该复习的时间。没学过的永远不算"到期"。
  bool get isDue {
    if (seen == 0 || dueAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= dueAt!;
  }

  PairStat copyWith({int? seen, int? right, int? box, int? dueAt}) => PairStat(
        seen: seen ?? this.seen,
        right: right ?? this.right,
        box: box ?? this.box,
        dueAt: dueAt ?? this.dueAt,
      );
}

class ProgressStore {
  static const _prefsKey = 'progress_v2';
  static const _keepDays = 60;

  /// 盒子 -> 间隔天数。
  static const _intervals = [0, 1, 2, 4, 7, 15, 30];

  static const maxBox = 6;

  final Map<String, PairStat> _pairs = {};
  final Map<String, int> _daily = {};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        loadFromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // 数据坏了就从头开始，不让它把整个 App 拖崩。
      }
    }
    _loaded = true;
  }

  void loadFromMap(Map<String, dynamic> data) {
    final pairs = data['pairs'] as Map<String, dynamic>? ?? {};
    _pairs.clear();
    pairs.forEach((key, value) {
      final item = value as Map<String, dynamic>;
      _pairs[key] = PairStat(
        seen: (item['seen'] as num?)?.toInt() ?? 0,
        right: (item['right'] as num?)?.toInt() ?? 0,
        box: (item['box'] as num?)?.toInt() ?? 0,
        dueAt: (item['dueAt'] as num?)?.toInt(),
      );
    });
    final daily = data['daily'] as Map<String, dynamic>? ?? {};
    _daily.clear();
    daily.forEach((key, value) {
      _daily[key] = (value as num).toInt();
    });
  }

  Map<String, dynamic> toJson() => {
        'pairs': _pairs.map(
          (key, value) => MapEntry(key, {
            'seen': value.seen,
            'right': value.right,
            'box': value.box,
            'dueAt': value.dueAt,
          }),
        ),
        'daily': _daily,
      };

  PairStat statFor(String pairId) => _pairs[pairId] ?? const PairStat();

  int get todayCount => _daily[_todayKey()] ?? 0;

  int get trainedPairs => _pairs.values.where((s) => s.seen > 0).length;

  int get overallAccuracy {
    var seen = 0;
    var right = 0;
    for (final s in _pairs.values) {
      seen += s.seen;
      right += s.right;
    }
    return seen == 0 ? 0 : (right / seen * 100).round();
  }

  /// 到期待复习的组数（只算学过的）。
  int dueCount(List<WordPair> pairs) =>
      pairs.where((p) => statFor(p.id).isDue).length;

  /// 还没学过的词对，按原顺序。
  List<WordPair> unlearned(List<WordPair> pairs) =>
      pairs.where((p) => !statFor(p.id).learned).toList();

  /// 复习队列：只包含学过的、且到期的词对，最早到期的排前面。
  List<WordPair> dueQueue(List<WordPair> pairs) {
    final due = pairs.where((p) => statFor(p.id).isDue).toList();
    due.sort((a, b) => (statFor(a.id).dueAt ?? 0).compareTo(
          statFor(b.id).dueAt ?? 0,
        ));
    return due;
  }

  Future<void> record(String pairId, bool isRight) async {
    final current = statFor(pairId);

    final nextBox = isRight
        ? math.min(current.box + 1, maxBox)
        : 0;
    final days = _intervals[nextBox];
    final due = DateTime.now()
        .add(Duration(days: days))
        .millisecondsSinceEpoch;

    _pairs[pairId] = PairStat(
      seen: current.seen + 1,
      right: current.right + (isRight ? 1 : 0),
      box: nextBox,
      dueAt: due,
    );

    final key = _todayKey();
    _daily[key] = (_daily[key] ?? 0) + 1;

    if (_daily.length > _keepDays) {
      final keys = _daily.keys.toList()..sort();
      for (final old in keys.take(_daily.length - _keepDays)) {
        _daily.remove(old);
      }
    }

    await _save();
  }

  Future<void> reset() async {
    _pairs.clear();
    _daily.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// 删掉某一组的记录（词对被删除时用）。
  Future<void> forget(String pairId) async {
    _pairs.remove(pairId);
    await _save();
  }

  /// 把内存里的状态写盘（导入备份后用）。
  Future<void> persist() => _save();

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

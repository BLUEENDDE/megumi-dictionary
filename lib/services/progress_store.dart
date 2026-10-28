import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 一组词的练习记录。
class PairStat {
  final int seen;
  final int right;

  const PairStat({this.seen = 0, this.right = 0});

  bool get untrained => seen == 0;

  double get accuracy => seen == 0 ? 0 : right / seen;

  int get accuracyPercent => (accuracy * 100).round();
}

/// 本地进度：存在 SharedPreferences 里，关掉 App 也不会丢。
class ProgressStore {
  static const _prefsKey = 'progress_v1';
  static const _keepDays = 60;

  final Map<String, PairStat> _pairs = {};
  final Map<String, int> _daily = {};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final pairs = data['pairs'] as Map<String, dynamic>? ?? {};
        pairs.forEach((key, value) {
          final item = value as Map<String, dynamic>;
          _pairs[key] = PairStat(
            seen: (item['seen'] as num?)?.toInt() ?? 0,
            right: (item['right'] as num?)?.toInt() ?? 0,
          );
        });
        final daily = data['daily'] as Map<String, dynamic>? ?? {};
        daily.forEach((key, value) {
          _daily[key] = (value as num).toInt();
        });
      } catch (_) {
        // 数据坏了就从头开始，不让它把整个 App 拖崩。
      }
    }
    _loaded = true;
  }

  PairStat statFor(String pairId) => _pairs[pairId] ?? const PairStat();

  int get todayCount => _daily[_todayKey()] ?? 0;

  /// 已经练过的组数。
  int get trainedPairs => _pairs.values.where((s) => s.seen > 0).length;

  /// 总正确率（只算练过的）。
  int get overallAccuracy {
    var seen = 0;
    var right = 0;
    for (final s in _pairs.values) {
      seen += s.seen;
      right += s.right;
    }
    return seen == 0 ? 0 : (right / seen * 100).round();
  }

  Future<void> record(String pairId, bool isRight) async {
    final current = statFor(pairId);
    _pairs[pairId] = PairStat(
      seen: current.seen + 1,
      right: current.right + (isRight ? 1 : 0),
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

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'pairs': _pairs.map(
        (key, value) => MapEntry(key, {
          'seen': value.seen,
          'right': value.right,
        }),
      ),
      'daily': _daily,
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

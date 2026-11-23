import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 浏览历史：最近看过的词条，最多保留 [maxItems] 条。
///
/// 达到上限后不再记录新词（重复看已有的词只会把它挪到最前面）。
class HistoryStore {
  static const _key = 'history_v1';
  static const maxItems = 20;

  static final HistoryStore instance = HistoryStore._();

  HistoryStore._();

  final List<String> _words = [];
  bool _loaded = false;

  List<String> get words => List.unmodifiable(_words);
  int get length => _words.length;
  bool get isFull => _words.length >= maxItems;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
      _words
        ..clear()
        ..addAll(list.take(maxItems));
    } catch (_) {
      // 坏数据忽略
    }
  }

  /// 记录一次浏览。已满则不再新增，返回是否写入了新词。
  Future<bool> add(String word) async {
    final w = word.trim();
    if (w.isEmpty) return false;

    final existing = _words.indexOf(w);
    if (existing >= 0) {
      _words.removeAt(existing);
      _words.insert(0, w);
      await _save();
      return false;
    }

    if (_words.length >= maxItems) return false;

    _words.insert(0, w);
    await _save();
    return true;
  }

  Future<void> clear() async {
    _words.clear();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_words));
  }
}

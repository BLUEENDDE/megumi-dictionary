import 'package:shared_preferences/shared_preferences.dart';

/// 浏览历史：看过多少记多少，最近看的排最前。
///
/// 不做数量上限；同一个词再看一次只把它挪到最前，不重复占位。
class HistoryStore {
  static const _key = 'history_v1';

  static final HistoryStore instance = HistoryStore._();

  HistoryStore._();

  final List<String> _words = [];
  bool _loaded = false;

  List<String> get words => List.unmodifiable(_words);
  int get length => _words.length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return;
    _words
      ..clear()
      ..addAll(raw);
  }

  /// 记一次浏览：已存在就挪到最前，否则插到最前。
  Future<void> add(String word) async {
    await load();
    final w = word.trim();
    if (w.isEmpty) return;
    _words.remove(w);
    _words.insert(0, w);
    await _save();
  }

  Future<void> clear() async {
    _words.clear();
    _loaded = true;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _words);
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置：目前只有主题模式，以后加东西也放这。
class SettingsStore {
  static const _themeKey = 'theme_mode';
  static const _batchKey = 'learn_batch';
  static const _backupKey = 'last_backup_at';
  static const _listKey = 'word_list';
  static const defaultBatch = 20;
  static const batchOptions = [5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  /// 全局主题模式，MaterialApp 监听它重建。
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// 一次学多少组，首页选择器改它。
  static final ValueNotifier<int> learnBatch =
      ValueNotifier<int>(defaultBatch);


  /// 词单：all / builtin / user。
  static const listOptions = <String, String>{
    'beginner': '初级',
    'intermediate': '中级',
    'advanced': '高级',
    'user': '自建词库',
  };

  static final ValueNotifier<String> wordList = ValueNotifier<String>('beginner');

  /// 上次导出备份的时间（毫秒），null 表示从未备份过。
  static final ValueNotifier<int?> lastBackupAt = ValueNotifier<int?>(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    themeMode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final batch = prefs.getInt(_batchKey);
    learnBatch.value = batchOptions.contains(batch) ? batch! : defaultBatch;

    lastBackupAt.value = prefs.getInt(_backupKey);

    final list = prefs.getString(_listKey);
    wordList.value = listOptions.containsKey(list) ? list! : 'beginner';
  }

  Future<void> markBackedUp() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    lastBackupAt.value = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backupKey, now);
  }

  Future<void> setWordList(String id) async {
    if (!listOptions.containsKey(id)) return;
    wordList.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey, id);
  }

  Future<void> setLearnBatch(int value) async {
    learnBatch.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_batchKey, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}

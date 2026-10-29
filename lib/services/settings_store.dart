import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置：目前只有主题模式，以后加东西也放这。
class SettingsStore {
  static const _themeKey = 'theme_mode';
  static const _batchKey = 'learn_batch';
  static const defaultBatch = 20;
  static const batchOptions = [5, 15, 20];

  /// 全局主题模式，MaterialApp 监听它重建。
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// 一次学多少组，首页选择器改它。
  static final ValueNotifier<int> learnBatch =
      ValueNotifier<int>(defaultBatch);

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

import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'services/settings_store.dart';
import 'theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore().load();
  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsStore.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'megumi辞書',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Palette.light, Brightness.light),
          darkTheme: buildTheme(Palette.dark, Brightness.dark),
          themeMode: mode,
          home: const RootShell(),
        );
      },
    );
  }
}

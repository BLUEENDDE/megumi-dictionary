import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => SelectionArea(child: child ?? const SizedBox()),
          theme: buildTheme(Palette.light, Brightness.light),
          darkTheme: buildTheme(Palette.dark, Brightness.dark),
          themeMode: mode,
          home: const RootShell(),
        );
      },
    );
  }
}

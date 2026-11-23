import 'package:flutter/material.dart';

import '../services/dictionary.dart';
import '../services/family_store.dart';
import '../services/history_store.dart';
import '../services/grammar_store.dart';
import '../services/progress_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import 'grammar_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// 底部三个页签：背词 / 语法 / 我的。左右滑动也能切。
class RootShell extends StatefulWidget {

  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final ProgressStore _progress = ProgressStore();
  final UserPairsStore _userPairs = UserPairsStore();
  final PageController _page = PageController();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  bool _ready = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _progress.load(),
      _userPairs.load(),
      Dictionary.load(),
      GrammarStore.load(),
    ]);
    await FamilyStore.load();
    await HistoryStore.instance.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _index) return;
    _page.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (!_ready) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
          ),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _page,
        onPageChanged: (index) {
          setState(() => _index = index);
          if (index == 0) _homeKey.currentState?.refresh();
        },
        children: [
          HomeScreen(
            key: _homeKey,
            progress: _progress,
            userPairs: _userPairs,
          ),
          const GrammarScreen(),
          SettingsScreen(
            progress: _progress,
            userPairs: _userPairs,
            embedded: true,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: 0.14),
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: p.muted),
            selectedIcon: Icon(Icons.menu_book_rounded, color: p.primary),
            label: '背词',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: p.muted),
            selectedIcon: Icon(Icons.school_rounded, color: p.primary),
            label: '语法',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: p.muted),
            selectedIcon: Icon(Icons.person_rounded, color: p.primary),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../services/dictionary.dart';
import '../services/family_store.dart';
import '../services/progress_store.dart';
import '../services/settings_store.dart';
import '../services/user_pairs_store.dart';
import '../services/user_words.dart';
import '../theme/palette.dart';
import '../widgets/dict_entry_sheet.dart';
import '../widgets/ui_kit.dart';
import 'family_screen.dart';
import 'learn_settings_screen.dart';
import 'word_quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final ProgressStore progress;
  final UserPairsStore userPairs;
  final String? initialQuery;

  const HomeScreen({
    super.key,
    required this.progress,
    required this.userPairs,
    this.initialQuery,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  final PageController _cards = PageController();

  String _query = '';
  List<DictEntry> _searchResults = const [];

  /// 列表显示多少页（每页 = 当前「每组词数」）
  int _pages = 1;

  int get _displayCount =>
      SettingsStore.learnBatch.value.clamp(1, 100) * _pages;

  List<DictEntry>? _levelCache;
  String? _levelCacheKey;
  int? _cLearned;
  int? _cMastered;
  int? _cDue;

  ProgressStore get _progress => widget.progress;

  @override
  void initState() {
    super.initState();
    Future.wait([Dictionary.load(), FamilyStore.load()]).then((_) {
      if (!mounted) return;
      final initial = widget.initialQuery;
      if (initial != null && initial.isNotEmpty) {
        _search.text = initial;
        _onSearch(initial);
      }
      // 词典刚加载完，之前缓存的空列表要作废
      _levelCache = null;
      setState(_recount);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _cards.dispose();
    super.dispose();
  }

  /// 从别的页面回来后刷新。
  void refresh() {
    if (mounted) setState(_recount);
  }

  void _recount() {
    _cLearned = null;
    _cMastered = null;
    _cDue = null;
  }

  void _onSearch(String value) {
    final q = value.trim();
    setState(() {
      _query = q;
      _searchResults = q.isEmpty ? const [] : _searchEntries(q);
    });
  }

  /// 搜索先列自建词，再列内置词典；同一个词只出现一次。
  List<DictEntry> _searchEntries(String q) {
    final lower = q.toLowerCase();
    final seen = <String>{};
    final mine = _userWords.where(
      (e) => e.word.toLowerCase().contains(lower),
    );
    return [
      ...mine,
      ...Dictionary.search(q, limit: 30),
    ].where((e) => seen.add(e.word.toLowerCase())).take(30).toList();
  }

  String get _listId => SettingsStore.wordList.value;

  int get _level => switch (_listId) {
        'intermediate' => 1,
        'advanced' => 2,
        _ => 0,
      };

  String get _listName => SettingsStore.listOptions[_listId] ?? '初级';

  /// 自建词库：把用户录的词对拆成单词条目，设置页加完词切回来就会刷新。
  List<DictEntry> get _userWords => dictEntriesFromPairs(widget.userPairs.pairs);

  List<DictEntry> get _levelWords {
    if (_listId == 'user') return _userWords;
    if (_levelCache != null && _levelCacheKey == _listId) return _levelCache!;
    _levelCache = Dictionary.allOf(level: _level);
    _levelCacheKey = _listId;
    return _levelCache!;
  }

  /// 出题用的干扰项池：自建词太少时拿初级词库补，免得凑不出四个选项。
  List<DictEntry> get _quizPool {
    if (_listId != 'user') return _levelWords;
    final mine = _userWords;
    if (mine.length >= 12) return mine;
    return [...mine, ...Dictionary.allOf(level: 0)];
  }

  String _wid(String word) => 'w:$word';

  int get _learnedCount =>
      _cLearned ??= _levelWords
          .where((e) => _progress.statFor(_wid(e.word)).learned)
          .length;

  int get _masteredCount =>
      _cMastered ??= _levelWords
          .where((e) => _progress.isMastered(_wid(e.word)))
          .length;

  int get _dueCount =>
      _cDue ??= _levelWords
          .where((e) => _progress.statFor(_wid(e.word)).isDue)
          .length;

  List<DictEntry> _unlearnedWords(int count) {
    final out = <DictEntry>[];
    for (final entry in _levelWords) {
      if (_progress.statFor(_wid(entry.word)).learned) continue;
      out.add(entry);
      if (out.length >= count) break;
    }
    return out;
  }

  List<DictEntry> _dueWords(int count) {
    final out = <DictEntry>[];
    for (final entry in _levelWords) {
      if (_progress.statFor(_wid(entry.word)).isDue) out.add(entry);
      if (out.length >= count) break;
    }
    return out;
  }

  Future<void> _runQuiz(List<DictEntry> words) async {
    if (words.isEmpty) return;
    await Navigator.of(context).push(
      fadeUpRoute(
        WordQuizScreen(
          title: _listName,
          words: words,
          pool: _quizPool,
          store: _progress,
        ),
      ),
    );
    if (!mounted) return;
    setState(_recount);
  }

  void _startReview() {
    if (_levelWords.isEmpty) {
      _toast(_emptyListHint);
      return;
    }
    final due = _dueWords(SettingsStore.learnBatch.value);
    if (due.isEmpty) {
      _toast('这一册还没有到期的单词');
      return;
    }
    _runQuiz(due);
  }

  void _startLearn() {
    if (_levelWords.isEmpty) {
      _toast(_emptyListHint);
      return;
    }
    final words = _unlearnedWords(SettingsStore.learnBatch.value);
    if (words.isEmpty) {
      _toast('这一册都学完了');
      return;
    }
    _runQuiz(words);
  }

  String get _emptyListHint =>
      _listId == 'user' ? '还没有自建单词，去「我的 → 添加单词」录几个' : '这一册还没有单词';

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickWordList() async {
    final p = context.pal;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bp = context.pal;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: bp.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              for (final category in SettingsStore.categories.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      category.key,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: bp.hint,
                      ),
                    ),
                  ),
                ),
                for (final id in category.value)
                  ListTile(
                    leading: _BookThumb(
                      width: 26,
                      height: 34,
                      muted: id == 'user',
                    ),
                    title: Text(
                      SettingsStore.listOptions[id] ?? id,
                      style: TextStyle(fontSize: 14.5, color: bp.ink),
                    ),
                    subtitle: Text(
                      _subtitleFor(id),
                      style: TextStyle(fontSize: 11.5, color: bp.hint),
                    ),
                    trailing: _listId == id
                        ? Icon(Icons.check_rounded, size: 18, color: bp.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(id),
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    await SettingsStore().setWordList(picked);
    if (!mounted) return;
    setState(() {
      _levelCache = null;
      _pages = 1;
      _recount();
    });
  }

  String _subtitleFor(String id) {
    final level = switch (id) {
      'beginner' => 0,
      'intermediate' => 1,
      'advanced' => 2,
      _ => null,
    };
    if (level == null) {
      final count = _userWords.length;
      return count == 0 ? '还没加词，去「我的」添加' : '$count 词';
    }
    return '${Dictionary.countOf(level: level)} 词';
  }

  Future<void> _openLearnSettings() async {
    await Navigator.of(context).push(fadeUpRoute(const LearnSettingsScreen()));
    if (!mounted) return;
    setState(() {
      _pages = 1;
      _recount();
    });
  }

  void _openFamily(String word) {
    final family = FamilyStore.familyOf(word);
    if (family == null) {
      _toast('「$word」还没有词族');
      return;
    }
    Navigator.of(context).push(fadeUpRoute(FamilyScreen(family: family)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final learned = _learnedCount;
    final mastered = _masteredCount;
    final due = _dueCount;
    final total = _levelWords.length;
    final words = _levelWords.take(_displayCount).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text(
              'MEGUMI · 辞書',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '背词',
              style: TextStyle(
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '一个词一个词地记，右边的小图标能看它的词根关系。',
              style: TextStyle(fontSize: 13.5, height: 1.6, color: p.muted),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 286,
              child: PageView(
                controller: _cards,
                children: [
                  _SummaryCard(
                    due: due,
                    learned: learned,
                    mastered: mastered,
                    total: total,
                    unlearned: total - learned,
                    listName: _listName,
                    onReview: _startReview,
                    onLearn: _startLearn,
                    onSettings: _openLearnSettings,
                    onPickList: _pickWordList,
                  ),
                  _ProgressCard(
                    mastered: mastered,
                    fresh: total - learned,
                    accuracy: _progress.overallAccuracy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 2; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == 0 ? p.primary : p.divider,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SearchBox(controller: _search, onChanged: _onSearch),
            if (_query.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '搜索结果',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_searchResults.length} 条',
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_searchResults.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '没找到「${_query.trim()}」',
                    style: TextStyle(fontSize: 13, color: p.hint),
                  ),
                ),
              for (final entry in _searchResults)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WordTile(
                    entry: entry,
                    onTap: () => showDictEntrySheet(context, entry),
                    onFamily: () => _openFamily(entry.word),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '词条',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${words.length} / $total',
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final entry in words)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WordTile(
                    entry: entry,
                    onTap: () => showDictEntrySheet(context, entry),
                    onFamily: () => _openFamily(entry.word),
                  ),
                ),
              if (words.length < total)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _pages += 1),
                      child: Text(
                        '加载更多',
                        style: TextStyle(fontSize: 13, color: p.primary),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int due;
  final int learned;
  final int mastered;
  final int total;
  final int unlearned;
  final String listName;
  final VoidCallback onReview;
  final VoidCallback onLearn;
  final VoidCallback onSettings;
  final VoidCallback onPickList;

  const _SummaryCard({
    required this.due,
    required this.learned,
    required this.mastered,
    required this.total,
    required this.unlearned,
    required this.listName,
    required this.onReview,
    required this.onLearn,
    required this.onSettings,
    required this.onPickList,
  });

  int get _daysLeft {
    final perDay = SettingsStore.learnBatch.value;
    if (unlearned <= 0 || perDay <= 0) return 0;
    return (unlearned / perDay).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const accent = Color(0xFFD93A56);
    final ratio = total == 0 ? 0.0 : learned / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Cover(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'megumi辞書',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '共 $total 词',
                      style: TextStyle(fontSize: 12.5, color: p.muted),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onPickList,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '选择词单',
                              style: TextStyle(fontSize: 11.5, color: p.hint),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              listName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: p.primary,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: p.hint,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.divider),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 12, color: p.muted),
                          children: [
                            const TextSpan(text: '预计学完还需 '),
                            TextSpan(
                              text: _daysLeft > 0 ? '$_daysLeft 天' : '—',
                              style: const TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: Icon(Icons.tune_rounded, size: 19, color: p.muted),
                tooltip: '背词设置',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: p.divider.withValues(alpha: 0.6),
              valueColor: const AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DotStat(count: mastered, label: '掌握', color: accent),
              const SizedBox(width: 16),
              _DotStat(count: learned, label: '已学', color: p.hint),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: onReview,
                    child: Text(
                      due > 0 ? '复习 $due' : '复习',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.ink,
                      side: BorderSide(color: p.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: onLearn,
                    child: const Text(
                      '新学',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 104,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A2E45), Color(0xFF3A1E2B)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'M',
              style: TextStyle(
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFDF0F3),
                fontFamily: 'serif',
              ),
            ),
          ),
          Positioned(
            left: 13,
            right: 8,
            bottom: 10,
            child: Container(
              height: 2,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _DotStat({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $count',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: p.ink,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int mastered;
  final int fresh;
  final int accuracy;

  const _ProgressCard({
    required this.mastered,
    required this.fresh,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BigStat(
                icon: Icons.workspace_premium_rounded,
                value: '$mastered',
                color: p.success,
              ),
              const SizedBox(width: 26),
              _BigStat(
                icon: Icons.fiber_new_rounded,
                value: '$fresh',
                color: p.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: p.hint,
              ),
              const SizedBox(width: 6),
              Text(
                '正确率 $accuracy%',
                style: TextStyle(fontSize: 12.5, color: p.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _BigStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 7),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: p.ink),
      decoration: InputDecoration(
        hintText: '搜词或关键词',
        hintStyle: TextStyle(fontSize: 13.5, color: p.hint),
        prefixIcon: Icon(Icons.search_rounded, size: 19, color: p.hint),
        isDense: true,
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// 单词条：左边级别、中间词和释义、右边词族按钮。
class _WordTile extends StatelessWidget {
  final DictEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFamily;

  const _WordTile({
    required this.entry,
    required this.onTap,
    required this.onFamily,
  });

  Color _levelColor(Palette p) => switch (entry.level) {
        userWordLevel => p.primary,
        0 => p.success,
        1 => p.primary,
        _ => p.hint,
      };

  String get _levelName => switch (entry.level) {
        userWordLevel => '自',
        0 => '初',
        1 => '中',
        _ => '高',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final levelColor = _levelColor(p);
    final hasFamily = FamilyStore.familyOf(entry.word) != null;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _levelName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: levelColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.word,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        entry.gloss.isEmpty ? '—' : entry.gloss,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: p.muted),
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(width: 6),
              _FamilyButton(onTap: onFamily, active: hasFamily),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool active;

  const _FamilyButton({required this.onTap, this.active = true});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Tooltip(
      message: '词根关系网',
      child: Material(
        color: p.primary.withValues(alpha: active ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: Icon(
              Icons.hub_outlined,
              size: 17,
              color: active ? p.primary : p.hint,
            ),
          ),
        ),
      ),
    );
  }
}

/// 词单里的小书封。
class _BookThumb extends StatelessWidget {
  final double width;
  final double height;
  final bool muted;

  const _BookThumb({
    required this.width,
    required this.height,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: muted
              ? const [Color(0xFFB9AEB4), Color(0xFF8C8189)]
              : const [Color(0xFF7A2E45), Color(0xFF3A1E2B)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'M',
          style: TextStyle(
            fontSize: height * 0.42,
            height: 1,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFDF0F3),
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
}
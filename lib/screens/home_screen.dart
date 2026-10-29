import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/dictionary.dart';
import '../services/progress_store.dart';
import '../services/settings_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import '../widgets/dict_entry_sheet.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';
import 'learn_settings_screen.dart';
import 'learned_list_screen.dart';
import 'quiz_screen.dart';
import 'word_quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<WordPair> pairs;
  final ProgressStore progress;
  final UserPairsStore userPairs;

  /// 预览用：带一个初始查询进来。
  final String? initialQuery;

  const HomeScreen({
    super.key,
    required this.pairs,
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
  List<DictEntry> _dictResults = const [];

  /// 点过「新学」之后才展示列表。
  bool _showPairs = false;

  /// 词典列表一次加载多少条。
  int _limit = 50;

  ProgressStore get _progress => widget.progress;
  UserPairsStore get _userPairs => widget.userPairs;

  @override
  void initState() {
    super.initState();
    Dictionary.load().then((_) {
      if (!mounted) return;
      final initial = widget.initialQuery;
      if (initial != null && initial.isNotEmpty) {
        _search.text = initial;
        _onSearch(initial);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _cards.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final q = value.trim();
    setState(() {
      _query = q;
      _dictResults = q.isEmpty ? const [] : Dictionary.search(q, limit: 20);
    });
  }

  // ---------- 词单 ----------

  String get _listId => SettingsStore.wordList.value;

  int? get _level => switch (_listId) {
        'beginner' => 0,
        'intermediate' => 1,
        'advanced' => 2,
        _ => null,
      };

  bool get _dictMode => _listId != 'user';

  /// 词对来源：全部词对 = 自建；分级页只看官方词条。
  List<WordPair> get _pairSource => _userPairs.pairs;

  List<DictEntry> get _dictList => _dictMode
      ? Dictionary.page(level: _level, offset: 0, limit: _limit)
      : const [];

  int get _dictTotal => _dictMode ? Dictionary.countOf(level: _level) : 0;

  void refresh() {
    if (mounted) setState(() {});
  }

  List<WordPair> get _visiblePairs {
    final base = _pairSource;
    if (_query.isEmpty) return base;
    final q = _query.toLowerCase();
    return base.where((pair) {
      return pair.first.form.toLowerCase().contains(q) ||
          pair.second.form.toLowerCase().contains(q) ||
          pair.summary.toLowerCase().contains(q) ||
          pair.tag.toLowerCase().contains(q);
    }).toList();
  }

  // ---------- 单词（官方词单） ----------

  List<DictEntry>? _levelCache;
  String? _levelCacheKey;

  List<DictEntry> _levelWords() {
    if (!_dictMode) return const [];
    if (_levelCache != null && _levelCacheKey == _listId) {
      return _levelCache!;
    }
    _levelCache = Dictionary.allOf(level: _level);
    _levelCacheKey = _listId;
    return _levelCache!;
  }

  String _wid(String word) => 'w:$word';

  List<DictEntry> _unlearnedWords(int count) {
    final out = <DictEntry>[];
    for (final entry in _levelWords()) {
      if (_progress.statFor(_wid(entry.word)).learned) continue;
      out.add(entry);
      if (out.length >= count) break;
    }
    return out;
  }

  List<DictEntry> _dueWords() {
    final out = <DictEntry>[];
    for (final entry in _levelWords()) {
      if (_progress.statFor(_wid(entry.word)).isDue) out.add(entry);
    }
    return out;
  }

  int _learnedWords() => _levelWords()
      .where((e) => _progress.statFor(_wid(e.word)).learned)
      .length;

  int _masteredWords() => _levelWords()
      .where((e) => _progress.isMastered(_wid(e.word)))
      .length;

  Future<void> _runWordQuiz(String title, List<DictEntry> words) async {
    await Navigator.of(context).push(
      fadeUpRoute(
        WordQuizScreen(
          title: title,
          words: words,
          pool: _levelWords(),
          store: _progress,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  // ---------- 动作 ----------

  Future<void> _startReview() async {
    if (_dictMode) {
      final due = _dueWords();
      if (due.isEmpty) {
        _toast('这一册还没有到期的单词');
        return;
      }
      final batch = due.take(SettingsStore.learnBatch.value).toList();
      await _runWordQuiz(_listName, batch);
      return;
    }

    final queue = _progress.dueQueue(_pairSource);
    if (queue.isEmpty) {
      _toast('这一单还没有到期的词对');
      return;
    }
    await Navigator.of(context).push(
      fadeUpRoute(QuizScreen(pairs: queue, store: _progress)),
    );
    if (mounted) setState(() {});
  }

  void _startLearn() {
    if (!_dictMode) {
      setState(() => _showPairs = true);
      return;
    }
    final words = _unlearnedWords(SettingsStore.learnBatch.value);
    if (words.isEmpty) {
      _toast('这一册都学完了');
      return;
    }
    _runWordQuiz(_listName, words);
  }

  String get _listName =>
      SettingsStore.listOptions[_listId] ?? '初级';

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
              for (final entry in SettingsStore.listOptions.entries)
                ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(fontSize: 14.5, color: bp.ink),
                  ),
                  trailing: SettingsStore.wordList.value == entry.key
                      ? Icon(Icons.check_rounded, size: 18, color: bp.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(entry.key),
                ),
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
      _showPairs = false;
      _limit = 50;
    });
  }

  Future<void> _openDetail(WordPair pair) async {
    await Navigator.of(context).push(
      fadeUpRoute(
        DetailScreen(pair: pair, store: _progress, userPairs: _userPairs),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openLearnedList() async {
    await Navigator.of(context).push(
      fadeUpRoute(
        LearnedListScreen(
          pairs: _pairSource,
          store: _progress,
          userPairs: _userPairs,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openLearnSettings() async {
    await Navigator.of(context).push(fadeUpRoute(const LearnSettingsScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _deletePair(WordPair pair) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final p = context.pal;
        return AlertDialog(
          title: const Text('删除这组词对？'),
          content: Text('${pair.first.form} / ${pair.second.form} 会被删掉，不能恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('算了'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('删除', style: TextStyle(color: p.danger)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _userPairs.remove(pair.id);
    await _progress.forget(pair.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final visible = _visiblePairs;
    final learned = _dictMode
        ? _learnedWords()
        : _progress.learnedPairs(_pairSource).length;
    final mastered = _dictMode
        ? _masteredWords()
        : _progress.masteredPairs(_pairSource).length;
    final due = _dictMode ? _dueWords().length : _progress.dueCount(_pairSource);
    final toLearn =
        _dictMode ? (_dictTotal - learned) : _progress.unlearned(_pairSource).length;
    final total = _dictMode ? _dictTotal : _pairSource.length;
    final dictItems =
        _showPairs && _query.isEmpty ? _dictList : const <DictEntry>[];

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
              '先看对比学一组，练过才进复习。',
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
                    unit: _dictMode ? '词' : '组',
                    unlearned: toLearn,
                    listName: SettingsStore.listOptions[_listId] ?? '全部词对',
                    onReview: _startReview,
                    onLearn: _startLearn,
                    onSettings: _openLearnSettings,
                    onLearned: _openLearnedList,
                    onPickList: _pickWordList,
                  ),
                  _ProgressCard(
                    mastered: mastered,
                    fresh: toLearn,
                    own: _userPairs.pairs.length,
                    accuracy: _progress.overallAccuracy,
                    onTap: _openLearnedList,
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
            if (_query.isNotEmpty && _dictResults.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '词典',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_dictResults.length} 条',
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in _dictResults)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DictTile(
                    entry: entry,
                    onTap: () => showDictEntrySheet(context, entry),
                  ),
                ),
            ],
            if (_showPairs) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    _dictMode ? '词条' : '词对',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dictMode
                        ? '${dictItems.length} / $_dictTotal'
                        : '${visible.length} 组',
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_dictMode && visible.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '自建词库还是空的',
                    style: TextStyle(fontSize: 13, color: p.hint),
                  ),
                ),
              for (final pair in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PairCard(
                    pair: pair,
                    stat: _progress.statFor(pair.id),
                    onTap: () => _openDetail(pair),
                    onLongPress:
                        pair.isUserMade ? () => _deletePair(pair) : null,
                  ),
                ),
              for (final entry in dictItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DictTile(
                    entry: entry,
                    onTap: () => showDictEntrySheet(context, entry),
                  ),
                ),
              if (_dictMode && dictItems.length < _dictTotal)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _limit += 50),
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

/// 主卡：参考词书 App 的布局——封面、书名、预计天数、进度条、复习/新学。
class _SummaryCard extends StatelessWidget {
  final int due;
  final int learned;
  final int mastered;
  final int total;
  final String unit;
  final int unlearned;
  final String listName;
  final VoidCallback onReview;
  final VoidCallback onLearn;
  final VoidCallback onSettings;
  final VoidCallback onLearned;
  final VoidCallback onPickList;

  const _SummaryCard({
    required this.due,
    required this.learned,
    required this.mastered,
    required this.total,
    required this.unit,
    required this.unlearned,
    required this.listName,
    required this.onReview,
    required this.onLearn,
    required this.onSettings,
    required this.onLearned,
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
              _Cover(),
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
                      '共 $total $unit',
                      style: TextStyle(fontSize: 12.5, color: p.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
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
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: p.hint,
                                  ),
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
                      ],
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
              const Spacer(),
              InkWell(
                onTap: onLearned,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '学习列表',
                        style: TextStyle(fontSize: 12.5, color: p.muted),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: p.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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

/// 小书封：深梅底 + 白色 M。
class _Cover extends StatelessWidget {
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
  final int own;
  final int accuracy;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.mastered,
    required this.fresh,
    required this.own,
    required this.accuracy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
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
                  const SizedBox(width: 26),
                  _BigStat(
                    icon: Icons.edit_note_rounded,
                    value: '$own',
                    color: p.muted,
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
              const Spacer(),
            ],
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
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

class _DictTile extends StatelessWidget {
  final DictEntry entry;
  final VoidCallback onTap;

  const _DictTile({required this.entry, required this.onTap});

  Color _levelColor(Palette p) => switch (entry.level) {
        0 => p.success,
        1 => p.primary,
        _ => p.hint,
      };

  String get _levelName => switch (entry.level) {
        0 => '初',
        1 => '中',
        _ => '高',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final levelColor = _levelColor(p);

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                  Text(
                    'p${entry.page}',
                    style: TextStyle(fontSize: 10.5, color: p.hint),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                entry.gloss.isEmpty ? '—' : entry.gloss,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, height: 1.6, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PairCard extends StatelessWidget {
  final WordPair pair;
  final PairStat stat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PairCard({
    required this.pair,
    required this.stat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: _word(pair.first.form, p)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 16,
                            color: p.primary.withValues(alpha: 0.7),
                          ),
                        ),
                        Flexible(child: _word(pair.second.form, p)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      pair.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: p.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            pair.tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          stat.untrained
                              ? '还没练过'
                              : '练 ${stat.seen} 次 · ${stat.accuracyPercent}%',
                          style: TextStyle(fontSize: 11, color: p.hint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: p.hint.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _word(String text, Palette p) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
      );
}

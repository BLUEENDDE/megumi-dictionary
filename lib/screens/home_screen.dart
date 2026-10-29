import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../services/settings_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';
import 'learn_session_screen.dart';
import 'learned_list_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<WordPair> pairs;
  final ProgressStore progress;
  final UserPairsStore userPairs;

  const HomeScreen({
    super.key,
    required this.pairs,
    required this.progress,
    required this.userPairs,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();

  String _query = '';

  ProgressStore get _progress => widget.progress;
  UserPairsStore get _userPairs => widget.userPairs;

  /// 从别的页面回来后刷新（进度可能变了）。
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WordPair> get _allPairs => [..._userPairs.pairs, ...widget.pairs];

  List<WordPair> get _visiblePairs {
    if (_query.isEmpty) return _allPairs;
    final q = _query.toLowerCase();
    return _allPairs.where((pair) {
      return pair.first.form.toLowerCase().contains(q) ||
          pair.second.form.toLowerCase().contains(q) ||
          pair.summary.toLowerCase().contains(q) ||
          pair.tag.toLowerCase().contains(q);
    }).toList();
  }

  /// 复习：只复习学过且到期的。
  Future<void> _startReview() async {
    final queue = _progress.dueQueue(_allPairs);
    if (queue.isEmpty) return;
    await Navigator.of(context).push(
      fadeUpRoute(QuizScreen(pairs: queue, store: _progress)),
    );
    if (mounted) setState(() {});
  }

  /// 学新词：按当前批量取一组，进学习会话。
  Future<void> _learnNext() async {
    final queue = _progress.unlearned(_allPairs);
    if (queue.isEmpty) return;
    final batch = queue.take(SettingsStore.learnBatch.value).toList();
    final learned = await Navigator.of(context).push<int>(
      fadeUpRoute(LearnSessionScreen(pairs: batch, store: _progress)),
    );
    if (!mounted) return;
    setState(() {});
    if (learned != null && learned > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('这一轮学会了 $learned 组')),
      );
    }
  }

  Future<void> _openLearnedList() async {
    await Navigator.of(context).push(
      fadeUpRoute(
        LearnedListScreen(
          pairs: _allPairs,
          store: _progress,
          userPairs: _userPairs,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDetail(WordPair pair) async {
    await Navigator.of(context).push(
      fadeUpRoute(
        DetailScreen(pair: pair, store: _progress, userPairs: _userPairs),
      ),
    );
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
    final loaded = _progress.isLoaded;
    final due = loaded ? _progress.dueCount(_allPairs) : 0;
    final toLearn = loaded ? _progress.unlearned(_allPairs).length : 0;
    final learned = loaded ? _progress.learnedPairs(_allPairs).length : 0;
    final mastered = loaded ? _progress.masteredPairs(_allPairs).length : 0;

    // 按钮统一叫"开始复习"：有到期的就复习，没到期的就先学新的。
    final bannerTitle = (due > 0 || toLearn > 0) ? '开始复习' : '今天练完了';
    final bannerTap = due > 0
        ? _startReview
        : toLearn > 0
            ? _learnNext
            : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INDONESIAN · 背词',
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '先看对比学一组，练过才进复习。',
              style: TextStyle(fontSize: 14, height: 1.6, color: p.muted),
            ),
            const SizedBox(height: 20),
            const _BatchSelector(),
            const SizedBox(height: 12),
            _ReviewBanner(
              title: bannerTitle,
              subtitle: _bannerSubtitle(due, toLearn),
              color: p.primary,
              foreground: context.isDark
                  ? const Color(0xFF10231F)
                  : Colors.white,
              onTap: bannerTap,
            ),
            const SizedBox(height: 12),
            _StatsRow(store: _progress, userCount: _userPairs.pairs.length),
            const SizedBox(height: 10),
            _LearnedEntry(
              learned: learned,
              mastered: mastered,
              fresh: toLearn,
              onTap: _openLearnedList,
            ),
            if (_allPairs.length > 4) ...[
              const SizedBox(height: 18),
              _SearchBox(
                controller: _search,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  '词对',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${visible.length} 组',
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 34),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '没有匹配的词对',
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
                  onLongPress: pair.isUserMade ? () => _deletePair(pair) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _bannerSubtitle(int due, int toLearn) {
    if (!_progress.isLoaded) return '${_allPairs.length} 组词对';
    if (due > 0) return '$due 组到期 · 按记忆曲线安排';
    if (toLearn > 0) {
      return '还有 $toLearn 组没学过 · 先看对比，练一次算学会';
    }
    if (_progress.todayCount > 0) {
      return '今天已练 ${_progress.todayCount} 题 · 明天再来';
    }
    return '全部学过了，明天再见';
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

class _StatsRow extends StatelessWidget {
  final ProgressStore store;
  final int userCount;

  const _StatsRow({required this.store, required this.userCount});

  @override
  Widget build(BuildContext context) {
    if (!store.isLoaded) return const SizedBox.shrink();
    final p = context.pal;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          _Stat(label: '练过', value: '${store.trainedPairs} 组'),
          const SizedBox(width: 18),
          _Stat(label: '正确率', value: '${store.overallAccuracy}%'),
          const Spacer(),
          Text(
            userCount == 0 ? '自建 0 组' : '自建 $userCount 组',
            style: TextStyle(fontSize: 12, color: p.muted),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: p.hint)),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
      ],
    );
  }
}

class _BatchSelector extends StatelessWidget {
  const _BatchSelector();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return ValueListenableBuilder<int>(
      valueListenable: SettingsStore.learnBatch,
      builder: (context, batch, _) {
        return Row(
          children: [
            Text(
              '一次记',
              style: TextStyle(fontSize: 12.5, color: p.muted),
            ),
            const SizedBox(width: 10),
            for (final n in SettingsStore.batchOptions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _BatchChip(
                  label: '$n',
                  selected: n == batch,
                  onTap: () => SettingsStore().setLearnBatch(n),
                ),
              ),
            const Spacer(),
            Text('个词对', style: TextStyle(fontSize: 12, color: p.hint)),
          ],
        );
      },
    );
  }
}

class _BatchChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BatchChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Material(
      color: selected ? p.primary : p.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? (context.isDark ? const Color(0xFF10231F) : Colors.white)
                  : p.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _LearnedEntry extends StatelessWidget {
  final int learned;
  final int mastered;
  final int fresh;
  final VoidCallback onTap;

  const _LearnedEntry({
    required this.learned,
    required this.mastered,
    required this.fresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_outlined, size: 18, color: p.muted),
              const SizedBox(width: 10),
              Text(
                '已学习 $learned 组',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· 掌握 $mastered',
                style: TextStyle(fontSize: 12, color: p.success),
              ),
              const SizedBox(width: 6),
              Text(
                '· 新学 $fresh',
                style: TextStyle(fontSize: 12, color: p.hint),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: p.hint.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color foreground;
  final VoidCallback? onTap;

  const _ReviewBanner({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final p = context.pal;

    return Material(
      color: disabled ? p.chipBg : color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: disabled
                      ? p.hint.withValues(alpha: 0.15)
                      : foreground.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  disabled ? Icons.check_rounded : Icons.play_arrow_rounded,
                  color: disabled ? p.hint : foreground,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: disabled ? p.muted : foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: disabled
                            ? p.hint
                            : foreground.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (!disabled)
                Icon(
                  Icons.arrow_forward_rounded,
                  color: foreground.withValues(alpha: 0.9),
                  size: 20,
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
                      style: TextStyle(fontSize: 13, height: 1.5, color: p.muted),
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

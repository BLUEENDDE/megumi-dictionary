import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../services/user_pairs_store.dart';
import '../widgets/ui_kit.dart';
import 'add_pair_screen.dart';
import 'detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<WordPair> pairs;

  const HomeScreen({super.key, required this.pairs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressStore _progress = ProgressStore();
  final UserPairsStore _userPairs = UserPairsStore();
  final TextEditingController _search = TextEditingController();

  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_progress.load(), _userPairs.load()]);
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

  Future<void> _openQuiz(List<WordPair> pairs) async {
    if (pairs.isEmpty) return;
    await Navigator.of(context).push(
      fadeUpRoute(QuizScreen(pairs: pairs, store: _progress)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addPair() async {
    final created = await Navigator.of(context).push<WordPair>(
      fadeUpRoute(const AddPairScreen()),
    );
    if (created == null) return;
    await _userPairs.add(created);
    if (mounted) setState(() {});
  }

  Future<void> _deletePair(WordPair pair) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这组词对？'),
        content: Text('${pair.first.form} / ${pair.second.form} 会被删掉，不能恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('算了'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFC2453E))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _userPairs.remove(pair.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const ink = Color(0xFF1C1B18);
    const muted = Color(0xFF6B6A63);
    final visible = _visiblePairs;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPair,
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          '添加词对',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const Text(
              'INDONESIAN · 辨析',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '易混词',
              style: TextStyle(
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '一次只比两个词，比一遍遍背释义有用。',
              style: TextStyle(fontSize: 14, height: 1.6, color: muted),
            ),
            const SizedBox(height: 24),
            _ReviewBanner(
              subtitle: _bannerSubtitle(),
              color: scheme.primary,
              onTap: () => _openQuiz(_allPairs),
            ),
            const SizedBox(height: 12),
            _StatsRow(store: _progress, userCount: _userPairs.pairs.length),
            if (_allPairs.length > 4) ...[
              const SizedBox(height: 18),
              _SearchBox(
                controller: _search,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                const Text(
                  '词对',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${visible.length} 组',
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 34),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '没有匹配的词对',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9A988F)),
                ),
              ),
            for (final pair in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PairCard(
                  pair: pair,
                  stat: _progress.statFor(pair.id),
                  onTap: () async {
                    await Navigator.of(context).push(
                      fadeUpRoute(
                        DetailScreen(pair: pair, store: _progress),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  onLongPress:
                      pair.isUserMade ? () => _deletePair(pair) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _bannerSubtitle() {
    if (!_progress.isLoaded) return '${_allPairs.length} 组词对';
    if (_progress.todayCount == 0) {
      return '${_allPairs.length} 组词对 · 约两分钟';
    }
    return '今天已练 ${_progress.todayCount} 题 · 继续加油';
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1B18)),
      decoration: InputDecoration(
        hintText: '搜词或关键词',
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFB0ADA3)),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 19,
          color: Color(0xFF9A988F),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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

    const muted = Color(0xFF8E8C82);

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
            style: const TextStyle(fontSize: 12, color: muted),
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
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF9A988F)),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A4941),
          ),
        ),
      ],
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReviewBanner({
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '开始复习',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.9),
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
    final scheme = Theme.of(context).colorScheme;
    const ink = Color(0xFF1C1B18);
    const muted = Color(0xFF6B6A63);

    return Material(
      color: Colors.white,
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
                        Flexible(
                          child: Text(
                            pair.first.form,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 16,
                            color: scheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            pair.second.form,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      pair.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: muted,
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
                            color: scheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            pair.tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          stat.untrained
                              ? '还没练过'
                              : '练 ${stat.seen} 次 · ${stat.accuracyPercent}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A988F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFFB9B7AE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

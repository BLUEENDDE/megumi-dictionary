import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<WordPair> pairs;

  const HomeScreen({super.key, required this.pairs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressStore _store = ProgressStore();

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openQuiz(List<WordPair> pairs) async {
    await Navigator.of(context).push(
      fadeUpRoute(QuizScreen(pairs: pairs, store: _store)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const ink = Color(0xFF1C1B18);
    const muted = Color(0xFF6B6A63);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              onTap: () => _openQuiz(widget.pairs),
            ),
            const SizedBox(height: 12),
            _StatsRow(store: _store),
            const SizedBox(height: 24),
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
                  '${widget.pairs.length} 组',
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final pair in widget.pairs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PairCard(
                  pair: pair,
                  stat: _store.statFor(pair.id),
                  onTap: () async {
                    await Navigator.of(context).push(
                      fadeUpRoute(
                        DetailScreen(pair: pair, store: _store),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _bannerSubtitle() {
    if (!_store.isLoaded) return '${widget.pairs.length} 组词对';
    if (_store.todayCount == 0) {
      return '${widget.pairs.length} 组词对 · 约两分钟';
    }
    return '今天已练 ${_store.todayCount} 题 · 继续加油';
  }
}

class _StatsRow extends StatelessWidget {
  final ProgressStore store;

  const _StatsRow({required this.store});

  @override
  Widget build(BuildContext context) {
    if (!store.isLoaded) return const SizedBox.shrink();

    const muted = Color(0xFF8E8C82);

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          _Stat(label: '练过', value: '${store.trainedPairs} 组'),
          const SizedBox(width: 20),
          _Stat(label: '总正确率', value: '${store.overallAccuracy}%'),
          const Spacer(),
          Text(
            store.todayCount == 0 ? '今天还没练' : '今天 ${store.todayCount} 题',
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

  const _PairCard({
    required this.pair,
    required this.stat,
    required this.onTap,
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

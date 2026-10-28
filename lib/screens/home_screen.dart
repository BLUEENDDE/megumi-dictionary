import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<WordPair> pairs;

  const HomeScreen({super.key, required this.pairs});

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
              count: pairs.length,
              color: scheme.primary,
              onTap: () => Navigator.of(context).push(
                fadeUpRoute(QuizScreen(pairs: pairs)),
              ),
            ),
            const SizedBox(height: 28),
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
                  '${pairs.length} 组',
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final pair in pairs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PairCard(
                  pair: pair,
                  onTap: () => Navigator.of(context).push(
                    fadeUpRoute(DetailScreen(pair: pair)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _ReviewBanner({
    required this.count,
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
                      '$count 道题 · 约两分钟',
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
  final VoidCallback onTap;

  const _PairCard({required this.pair, required this.onTap});

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
                      crossAxisAlignment: CrossAxisAlignment.center,
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

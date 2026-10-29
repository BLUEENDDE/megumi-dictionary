import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../theme/palette.dart';
import '../widgets/pair_detail_view.dart';
import '../widgets/ui_kit.dart';
import 'family_screen.dart';
import 'quiz_screen.dart';

/// 一次学一批：逐组看对比，练过一次就自动进下一组。
class LearnSessionScreen extends StatefulWidget {
  final List<WordPair> pairs;
  final ProgressStore store;

  const LearnSessionScreen({
    super.key,
    required this.pairs,
    required this.store,
  });

  @override
  State<LearnSessionScreen> createState() => _LearnSessionScreenState();
}

class _LearnSessionScreenState extends State<LearnSessionScreen> {
  int _index = 0;
  int _learned = 0;

  WordPair get _current => widget.pairs[_index];

  Future<void> _practice() async {
    final before = widget.store.statFor(_current.id).learned;
    await Navigator.of(context).push(
      fadeUpRoute(QuizScreen(pairs: [_current], store: widget.store)),
    );
    final after = widget.store.statFor(_current.id).learned;
    if (!mounted) return;
    if (!before && after) _learned++;
    setState(_advance);
  }

  void _advance() {
    if (_index + 1 >= widget.pairs.length) {
      Navigator.of(context).pop(_learned);
      return;
    }
    _index++;
  }

  void _skip() {
    setState(_advance);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final progress = (_index + 1) / widget.pairs.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_learned);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(_learned),
          ),
          title: Text(
            '学新词 ${_index + 1} / ${widget.pairs.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: p.muted,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: p.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                ),
              ),
            ),
            Expanded(
              child: PairDetailView(
                pair: _current,
                onOpenFamily: (family) {
                  Navigator.of(context).push(
                    fadeUpRoute(FamilyScreen(family: family)),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              TextButton(
                onPressed: _skip,
                child: Text(
                  '跳过',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: context.isDark
                          ? const Color(0xFF10231F)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _practice,
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: const Text(
                      '练这一组，学会了',
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
        ),
      ),
    );
  }
}

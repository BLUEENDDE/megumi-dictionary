import 'package:flutter/material.dart';

import '../services/grammar_store.dart';
import '../theme/palette.dart';

/// 语法练习：只练不测，选完立刻给解释，不计分、不记录。
class GrammarPracticeScreen extends StatefulWidget {
  final GrammarPoint point;

  const GrammarPracticeScreen({super.key, required this.point});

  @override
  State<GrammarPracticeScreen> createState() => _GrammarPracticeScreenState();
}

class _GrammarPracticeScreenState extends State<GrammarPracticeScreen> {
  int _index = 0;
  String? _picked;
  bool _done = false;

  List<GrammarPractice> get _items => widget.point.practice;

  void _pick(GrammarPractice item, String option) {
    if (_picked != null) return;
    setState(() => _picked = option);
  }

  void _next() {
    if (_index + 1 >= _items.length) {
      setState(() => _done = true);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('练习')),
        body: Center(
          child: Text('暂无练习', style: TextStyle(color: p.muted)),
        ),
      );
    }

    if (_done) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 48, color: p.success),
                const SizedBox(height: 14),
                Text(
                  '这组练完了',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '不计分，随时可以再来一遍',
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: context.isDark
                          ? const Color(0xFF10231F)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text(
                      '完成',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _items[_index];
    final answered = _picked != null;
    final right = _picked == item.answer;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.point.title} · ${_index + 1}/${_items.length}',
          style: TextStyle(fontSize: 14, color: p.muted),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                item.q,
                style: TextStyle(
                  fontSize: 16.5,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final option in item.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Option(
                  text: option,
                  state: _stateOf(option, item, answered),
                  onTap: answered ? null : () => _pick(item, option),
                ),
              ),
            if (answered) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: right
                      ? p.success.withValues(alpha: 0.08)
                      : p.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      right ? '对了' : '再想想：正确答案是「${item.answer}」',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: right ? p.success : p.danger,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.why,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.6,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: context.isDark
                        ? const Color(0xFF10231F)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _next,
                  child: Text(
                    _index + 1 >= _items.length ? '练完了' : '下一题',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _OptionState _stateOf(String option, GrammarPractice item, bool answered) {
    if (!answered) return _OptionState.idle;
    if (option == item.answer) return _OptionState.correct;
    if (option == _picked) return _OptionState.wrong;
    return _OptionState.dim;
  }
}

enum _OptionState { idle, correct, wrong, dim }

class _Option extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  const _Option({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    late final Color border;
    late final Color fill;
    late final Color ink;

    switch (state) {
      case _OptionState.idle:
        border = p.divider;
        fill = p.card;
        ink = p.ink;
      case _OptionState.correct:
        border = p.success;
        fill = p.success.withValues(alpha: 0.08);
        ink = p.success;
      case _OptionState.wrong:
        border = p.danger;
        fill = p.danger.withValues(alpha: 0.08);
        ink = p.danger;
      case _OptionState.dim:
        border = p.divider;
        fill = p.chipBg;
        ink = p.hint;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.5, color: ink),
            ),
          ),
        ),
      ),
    );
  }
}

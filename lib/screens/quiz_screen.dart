import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../theme/palette.dart';

enum _OptionState { idle, correct, wrong, dim }

class QuizScreen extends StatefulWidget {
  final List<WordPair> pairs;
  final ProgressStore? store;

  /// 仅用于截图预览：right = 自动选对，wrong = 自动选错。正式使用留空。
  final String? previewAnswer;

  const QuizScreen({
    super.key,
    required this.pairs,
    this.store,
    this.previewAnswer,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late final List<QuizItem> _items;
  late final AnimationController _shake;

  int _index = 0;
  String? _selected;
  int _correct = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _items = _buildItems(widget.pairs);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final preview = widget.previewAnswer;
    if (preview != null && _items.isNotEmpty) {
      final first = _items.first;
      final target = preview == 'right'
          ? first.answer
          : first.options.firstWhere((o) => o != first.answer);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _choose(target);
      });
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  List<QuizItem> _buildItems(List<WordPair> pairs) {
    final random = math.Random();
    final items = <QuizItem>[];

    for (final pair in pairs) {
      final useFirst = random.nextBool();
      final answer = useFirst ? pair.first.form : pair.second.form;
      final other = useFirst ? pair.second.form : pair.first.form;
      final sentence =
          useFirst ? pair.example.firstText : pair.example.secondText;
      final gloss = useFirst ? pair.example.firstGloss : pair.example.secondGloss;
      final note = useFirst ? pair.example.firstNote : pair.example.secondNote;

      // 例句里没有目标词就出不了填空题，跳过（用户自建的可能没填例句）。
      if (!sentence.toLowerCase().contains(answer.toLowerCase())) {
        continue;
      }

      final options = <String>[answer, other]..shuffle(random);

      items.add(
        QuizItem(
          pair: pair,
          prompt: _blankOut(sentence, answer),
          gloss: gloss,
          answer: answer,
          options: options,
          note: note,
        ),
      );
    }

    items.shuffle(random);
    return items;
  }

  String _blankOut(String sentence, String word) {
    final index = sentence.toLowerCase().indexOf(word.toLowerCase());
    if (index < 0) return sentence;
    return '${sentence.substring(0, index)}____'
        '${sentence.substring(index + word.length)}';
  }

  void _choose(String option) {
    if (_selected != null) return;

    final item = _items[_index];
    final isRight = option == item.answer;

    setState(() {
      _selected = option;
      if (isRight) _correct++;
    });

    widget.store?.record(item.pair.id, isRight);

    if (isRight) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  void _next() {
    if (_index + 1 >= _items.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _correct = 0;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '这些词对还没有能出题的例句。\n去词对详情里补一条包含该词的句子，就能练了。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.7, color: p.muted),
            ),
          ),
        ),
      );
    }

    if (_finished) {
      return _ResultView(
        total: _items.length,
        correct: _correct,
        onRestart: _restart,
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    final item = _items[_index];
    final answered = _selected != null;
    final isRight = _selected == item.answer;
    final progress = (_index + (answered ? 1 : 0)) / _items.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '第 ${_index + 1} / ${_items.length} 题',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: p.muted,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '答对 $_correct',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: p.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                children: [
                  Text(
                    '选词填空',
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: p.hint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      item.prompt,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final t = _shake.value;
                      final dx = math.sin(t * math.pi * 5) * (1 - t) * 10;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        for (final option in item.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OptionButton(
                              label: option,
                              state: _stateFor(option, item, answered),
                              onTap: answered ? null : () => _choose(option),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: answered
                        ? Padding(
                            key: ValueKey('feedback-$_index'),
                            padding: const EdgeInsets.only(top: 12),
                            child: _FeedbackCard(isRight: isRight, item: item),
                          )
                        : Padding(
                            key: const ValueKey('hint'),
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              '想不起来也没关系，选完会告诉你这两个词差在哪。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: p.hint,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: answered ? 1 : 0,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
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
                    onPressed: answered ? _next : null,
                    child: Text(
                      _index + 1 >= _items.length ? '看结果' : '继续',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _OptionState _stateFor(String option, QuizItem item, bool answered) {
    if (!answered) return _OptionState.idle;
    if (option == item.answer) return _OptionState.correct;
    if (option == _selected) return _OptionState.wrong;
    return _OptionState.dim;
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    late final Color border;
    late final Color fill;
    late final Color text;
    IconData? icon;

    switch (state) {
      case _OptionState.idle:
        border = p.divider;
        fill = p.card;
        text = p.ink;
      case _OptionState.correct:
        border = p.success;
        fill = p.success.withValues(alpha: 0.1);
        text = p.success;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        border = p.danger;
        fill = p.danger.withValues(alpha: 0.1);
        text = p.danger;
        icon = Icons.cancel_rounded;
      case _OptionState.dim:
        border = p.divider.withValues(alpha: 0.6);
        fill = p.chipBg.withValues(alpha: 0.5);
        text = p.hint;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 20, color: text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final bool isRight;
  final QuizItem item;

  const _FeedbackCard({required this.isRight, required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = isRight ? p.success : p.danger;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRight ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isRight ? '对了' : '答案是 ${item.answer}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (item.gloss.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.gloss,
              style: TextStyle(fontSize: 13, height: 1.55, color: p.muted),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            item.note,
            style: TextStyle(fontSize: 12, height: 1.5, color: p.hint),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.pair.first.form} vs ${item.pair.second.form}：${item.pair.summary}',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: p.primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int total;
  final int correct;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _ResultView({
    required this.total,
    required this.correct,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final ratio = total == 0 ? 0.0 : correct / total;
    final message = ratio >= 0.9
        ? '这组已经很稳了'
        : ratio >= 0.6
            ? '有印象，再刷一遍会更好'
            : '先回词对里再看一眼对比';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            children: [
              const Spacer(),
              Text(
                '$correct / $total',
                style: TextStyle(
                  fontSize: 56,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(fontSize: 14, height: 1.6, color: p.muted),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: p.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor:
                        context.isDark ? const Color(0xFF10231F) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onRestart,
                  child: const Text(
                    '再来一遍',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: TextButton(
                  onPressed: onClose,
                  child: Text(
                    '回到词对',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.muted,
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

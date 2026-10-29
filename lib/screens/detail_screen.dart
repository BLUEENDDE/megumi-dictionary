import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import '../widgets/pair_detail_view.dart';
import '../widgets/ui_kit.dart';
import 'add_pair_screen.dart';
import 'family_screen.dart';
import 'quiz_screen.dart';

class DetailScreen extends StatefulWidget {
  final WordPair pair;
  final ProgressStore store;
  final UserPairsStore? userPairs;

  const DetailScreen({
    super.key,
    required this.pair,
    required this.store,
    this.userPairs,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late WordPair _pair;

  @override
  void initState() {
    super.initState();
    _pair = widget.pair;
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<WordPair>(
      fadeUpRoute(AddPairScreen(initial: _pair)),
    );
    if (updated == null) return;
    await widget.userPairs?.update(updated);
    if (!mounted) return;
    setState(() => _pair = updated);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final editable = _pair.isUserMade && widget.userPairs != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('${_pair.first.form} / ${_pair.second.form}'),
        actions: [
          if (editable)
            IconButton(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: '编辑',
            ),
        ],
      ),
      body: PairDetailView(
        pair: _pair,
        onOpenFamily: (family) {
          Navigator.of(context).push(fadeUpRoute(FamilyScreen(family: family)));
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor:
                  context.isDark ? const Color(0xFF10231F) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                fadeUpRoute(QuizScreen(pairs: [_pair], store: widget.store)),
              );
            },
            icon: const Icon(Icons.bolt_rounded, size: 20),
            label: const Text(
              '练这一组',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/dictionary.dart';
import '../theme/palette.dart';

class DictionaryScreen extends StatefulWidget {
  /// 预览用：直接带一个查询进来。
  final String? initialQuery;

  const DictionaryScreen({super.key, this.initialQuery});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _query = TextEditingController();
  List<DictEntry> _results = const [];

  @override
  void initState() {
    super.initState();
    _query.addListener(_run);
    Dictionary.load().then((_) {
      if (!mounted) return;
      final initial = widget.initialQuery;
      if (initial != null && initial.isNotEmpty) {
        _query.text = initial;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _query.removeListener(_run);
    _query.dispose();
    super.dispose();
  }

  void _run() {
    setState(() => _results = Dictionary.search(_query.text));
  }

  void _open(DictEntry entry) {
    final p = context.pal;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final bp = context.pal;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bp.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                entry.word,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: bp.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '原文第 ${entry.page} 页',
                style: TextStyle(fontSize: 11.5, color: bp.hint),
              ),
              const SizedBox(height: 14),
              Text(
                entry.gloss.isEmpty ? '（这一条没识别出释义）' : entry.gloss,
                style: TextStyle(fontSize: 14.5, height: 1.75, color: bp.ink),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: '${entry.word}\n${entry.gloss}'),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('复制'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final hasQuery = _query.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('词典'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${Dictionary.size} 条',
                style: TextStyle(fontSize: 12, color: p.hint),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _query,
              autocorrect: false,
              style: TextStyle(fontSize: 15, color: p.ink),
              decoration: InputDecoration(
                hintText: '输入印尼语单词',
                hintStyle: TextStyle(fontSize: 14, color: p.hint),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.hint),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: p.hint),
                        onPressed: () => _query.clear(),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: p.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: !hasQuery
                ? _Hint(sample: Dictionary.sample(6), onOpen: _open)
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          '没有找到「${_query.text.trim()}」',
                          style: TextStyle(fontSize: 13, color: p.hint),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = _results[index];
                          return _EntryTile(
                            entry: entry,
                            onTap: () => _open(entry),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final List<DictEntry> sample;
  final ValueChanged<DictEntry> onOpen;

  const _Hint({required this.sample, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '输入一个词，查它的中文释义。数据来自《印度尼西亚语-汉语大词典》扫描本，已全部内置，离线可查。',
          style: TextStyle(fontSize: 12.5, height: 1.7, color: p.muted),
        ),
        const SizedBox(height: 18),
        Text(
          '随手看看',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: p.hint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in sample)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EntryTile(
              entry: entry,
              onTap: () => onOpen(entry),
            ),
          ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DictEntry entry;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, required this.onTap});

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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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

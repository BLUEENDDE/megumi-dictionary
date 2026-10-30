import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/family_screen.dart';
import '../services/dictionary.dart';
import '../services/family_store.dart';
import '../theme/palette.dart';
import 'ui_kit.dart';

/// 词典条目的详情弹层：词性、释义、例句与翻译。
void showDictEntrySheet(BuildContext context, DictEntry entry) {
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
      final family = FamilyStore.familyOf(entry.word);

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
            if (entry.pos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bp.chipBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.pos,
                      style: TextStyle(fontSize: 11, color: bp.muted),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Text(
              entry.gloss.isEmpty ? '（这一条没识别出释义）' : entry.gloss,
              style: TextStyle(fontSize: 14.5, height: 1.75, color: bp.ink),
            ),
            if (entry.example.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: bp.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '例句',
                      style: TextStyle(fontSize: 10.5, color: bp.hint),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.example,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: bp.ink,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (entry.exampleCn.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.exampleCn,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: bp.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final text = [
                      entry.word,
                      if (entry.pos.isNotEmpty) entry.pos,
                      entry.gloss,
                      if (entry.example.isNotEmpty) entry.example,
                      if (entry.exampleCn.isNotEmpty) entry.exampleCn,
                    ].join('\n');
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('复制'),
                ),
                const SizedBox(width: 10),
                if (family != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        fadeUpRoute(FamilyScreen(family: family)),
                      );
                    },
                    icon: const Icon(Icons.hub_outlined, size: 16),
                    label: const Text('词根关系'),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

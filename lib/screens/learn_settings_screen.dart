import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../theme/palette.dart';

/// 背词设置：每组学多少对词。
class LearnSettingsScreen extends StatelessWidget {
  const LearnSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('背词设置'),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: SettingsStore.learnBatch,
        builder: (context, current, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '这里选的是「每组学多少对词」。选 5 就是一次出现 5 对，选 100 就是 100 对。',
                  style: TextStyle(fontSize: 12.5, height: 1.7, color: p.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '每组词数',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < SettingsStore.batchOptions.length; i++) ...[
                      if (i > 0) Divider(color: p.divider, height: 1),
                      InkWell(
                        onTap: () => SettingsStore().setLearnBatch(
                          SettingsStore.batchOptions[i],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${SettingsStore.batchOptions[i]} 对',
                                style: TextStyle(fontSize: 14, color: p.ink),
                              ),
                              const Spacer(),
                              if (current == SettingsStore.batchOptions[i])
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: p.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

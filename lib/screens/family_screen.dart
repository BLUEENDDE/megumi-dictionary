import 'package:flutter/material.dart';

import '../models/word_family.dart';
import '../theme/palette.dart';

class FamilyScreen extends StatefulWidget {
  final WordFamily family;

  const FamilyScreen({super.key, required this.family});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  int? _expanded = 0;

  Color _affixColor(String affix, Palette p) {
    final a = affix.toLowerCase();
    if (a.startsWith('me')) return p.primary;
    if (a.startsWith('di')) return const Color(0xFF3F7DBF);
    if (a.startsWith('pe') || a.startsWith('pem') || a.startsWith('pen')) {
      return const Color(0xFFC07A2E);
    }
    if (a.startsWith('ter')) return const Color(0xFF8A6BC0);
    if (a.startsWith('ber')) return const Color(0xFF3F8F5A);
    if (a.startsWith('ke')) return const Color(0xFFB05A7A);
    if (a.startsWith('per')) return const Color(0xFFA9803A);
    if (a.startsWith('-')) return const Color(0xFF6B7A8F);
    return p.muted;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final family = widget.family;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('词根 ${family.root}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      family.root,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.chipBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '词根',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: p.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  family.rootGloss,
                  style: TextStyle(fontSize: 14, color: p.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  family.rootNote,
                  style: TextStyle(fontSize: 12.5, height: 1.7, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '派生词',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${family.members.length} 个 · 点开看词缀作用',
                style: TextStyle(fontSize: 12.5, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < family.members.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: CustomPaint(
                      painter: _BranchPainter(
                        first: i == 0,
                        last: i == family.members.length - 1,
                        lineColor: p.divider,
                        dotColor: _affixColor(family.members[i].affix, p),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MemberCard(
                        member: family.members[i],
                        color: _affixColor(family.members[i].affix, p),
                        expanded: _expanded == i,
                        onTap: () => setState(
                          () => _expanded = _expanded == i ? null : i,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BranchPainter extends CustomPainter {
  final bool first;
  final bool last;
  final Color lineColor;
  final Color dotColor;

  _BranchPainter({
    required this.first,
    required this.last,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final centerY = size.height / 2;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // 竖线：从上一个节点连下来
    final top = first ? centerY : 0.0;
    canvas.drawLine(Offset(x, top), Offset(x, centerY), line);

    // 竖线：连到下一个节点
    if (!last) {
      canvas.drawLine(Offset(x, centerY), Offset(x, size.height), line);
    }

    // 横线：伸向卡片
    canvas.drawLine(Offset(x, centerY), Offset(size.width, centerY), line);

    // 节点小圆点
    canvas.drawCircle(
      Offset(x, centerY),
      3.4,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(_BranchPainter old) =>
      old.first != first ||
      old.last != last ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor;
}

class _MemberCard extends StatelessWidget {
  final DerivedWord member;
  final Color color;
  final bool expanded;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.color,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.affix,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        member.form,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: p.hint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  member.gloss,
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: p.muted),
                ),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      member.note,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.6,
                        color: p.hint,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

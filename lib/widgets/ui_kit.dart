import 'package:flutter/material.dart';

/// 统一的页面转场：淡入 + 轻微上移。
Route<T> fadeUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 把句子里出现的目标单词加粗染色。
Widget highlightedText(
  String text,
  String word, {
  TextStyle? style,
  Color? highlightColor,
}) {
  final base = style ?? const TextStyle();
  final lower = text.toLowerCase();
  final index = lower.indexOf(word.toLowerCase());
  if (index < 0) {
    return Text(text, style: base);
  }
  return RichText(
    text: TextSpan(
      style: base,
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + word.length),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: highlightColor ?? base.color,
          ),
        ),
        TextSpan(text: text.substring(index + word.length)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

class MobileLayoutWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MobileLayoutWrapper({
    super.key,
    required this.child,
    this.maxWidth = 550.0, // 모바일 웹을 고려해 480 -> 600으로 조금 늘렸습니다.
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: child,
      ),
    );
  }
}
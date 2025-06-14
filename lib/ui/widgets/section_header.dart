import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isSecondary;

  const SectionHeader({
    super.key,
    required this.title,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isSecondary ? Colors.white54 : Colors.white,
      ),
    );
  }
} 
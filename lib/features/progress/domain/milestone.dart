import 'package:flutter/material.dart';

class Milestone {
  const Milestone({
    required this.title,
    required this.icon,
    required this.isEarned,
  });

  final String title;
  final IconData icon;
  final bool isEarned;
}

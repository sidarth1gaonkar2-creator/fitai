import 'package:flutter/cupertino.dart';

import '../../../../core/theme/field_manual.dart';

/// Static Field Manual skeleton shown while the profile loads — mirrors the
/// Morning Briefing layout (orders, rank strip, rations panel). Static by
/// design: no shimmer means nothing to silence under reduced motion.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget panel(double height) => Container(
          height: height,
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
          ),
        );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        panel(150),
        const SizedBox(height: 12),
        panel(88),
        const SizedBox(height: 12),
        panel(300),
        const SizedBox(height: 12),
        panel(68),
        const SizedBox(height: 12),
        panel(100),
      ],
    );
  }
}

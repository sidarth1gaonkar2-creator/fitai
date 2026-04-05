import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_loading.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Calorie ring
          Center(child: ShimmerBox(width: 200, height: 200, borderRadius: 100)),
          SizedBox(height: 24),
          // Macro row
          Row(children: [
            Expanded(child: ShimmerBox(width: 100, height: 50)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(width: 100, height: 50)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(width: 100, height: 50)),
          ]),
          SizedBox(height: 20),
          // Streak + Water
          Row(children: [
            Expanded(child: ShimmerBox(width: 100, height: 120, borderRadius: 12)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(width: 100, height: 120, borderRadius: 12)),
          ]),
          SizedBox(height: 16),
          // Today workout card
          ShimmerCard(height: 100),
          SizedBox(height: 24),
          // Quick action buttons
          Row(children: [
            Expanded(child: ShimmerBox(width: 100, height: 48, borderRadius: 24)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(width: 100, height: 48, borderRadius: 24)),
          ]),
        ],
      ),
    );
  }
}

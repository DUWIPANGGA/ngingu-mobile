import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Blok placeholder berdenyut untuk skeleton loading.
class PulseBlock extends StatefulWidget {
  const PulseBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<PulseBlock> createState() => _PulseBlockState();
}

class _PulseBlockState extends State<PulseBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 0.95,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.softSky,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Skeleton dashboard home (sapaan + kartu statistik + kartu konten).
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: const [
        Row(
          children: [
            PulseBlock(width: 46, height: 46, radius: 23),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PulseBlock(width: 150, height: 16),
                  SizedBox(height: 8),
                  PulseBlock(width: 110, height: 12),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        PulseBlock(width: double.infinity, height: 132, radius: 16),
        SizedBox(height: 12),
        PulseBlock(width: double.infinity, height: 96, radius: 16),
        SizedBox(height: 12),
        PulseBlock(width: double.infinity, height: 178, radius: 16),
      ],
    );
  }
}

/// Skeleton daftar kartu ensiklopedia.
class DiseaseListSkeleton extends StatelessWidget {
  const DiseaseListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PulseBlock(width: 52, height: 52, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PulseBlock(width: 140, height: 14),
                      SizedBox(height: 8),
                      PulseBlock(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            PulseBlock(width: double.infinity, height: 12),
            SizedBox(height: 6),
            PulseBlock(width: 180, height: 12),
          ],
        ),
      ),
    );
  }
}

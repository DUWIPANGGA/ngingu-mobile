import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';

/// Swipeable post gallery with page dots (§6.4 `image_urls`).
class ForumImageGallery extends StatefulWidget {
  const ForumImageGallery({super.key, required this.urls, this.height = 220});

  final List<String> urls;
  final double height;

  @override
  State<ForumImageGallery> createState() => _ForumImageGalleryState();
}

class _ForumImageGalleryState extends State<ForumImageGallery> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();
    final single = widget.urls.length == 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final url = resolveImageUrl(widget.urls[i]);
                return GestureDetector(
                  onTap: () => _openFull(context, i),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.softSky,
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.softSky,
                      child: const Icon(Icons.broken_image_outlined,
                          size: 34, color: AppColors.primary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (!single)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.urls.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  void _openFull(BuildContext context, int initial) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: resolveImageUrl(widget.urls[initial]),
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image_outlined,
                        size: 40, color: Colors.white70),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of small comment images (max 3 — §2.7), tap to enlarge.
class ForumImageStrip extends StatelessWidget {
  const ForumImageStrip({super.key, required this.urls, this.size = 76});

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final raw in urls.take(3))
            InkWell(
              onTap: () => _open(context, raw),
              borderRadius: BorderRadius.circular(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: resolveImageUrl(raw),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                      width: size, height: size, color: AppColors.softSky),
                  errorWidget: (_, _, _) => Container(
                    width: size,
                    height: size,
                    color: AppColors.softSky,
                    child: const Icon(Icons.image_outlined,
                        size: 20, color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String raw) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: resolveImageUrl(raw),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picked (local) image thumbnails with per-item remove + dashed add tile.
class ForumPickedImages extends StatelessWidget {
  const ForumPickedImages({
    super.key,
    required this.files,
    required this.onRemove,
    this.onAdd,
    this.max = 5,
    this.size = 72,
    this.addLabel = 'Tambah foto',
  });

  final List<File> files;
  final ValueChanged<int> onRemove;
  final VoidCallback? onAdd;
  final int max;
  final double size;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < files.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      files[i],
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: InkWell(
                      onTap: () => onRemove(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (onAdd != null && files.length < max)
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: DashedRoundedPainter(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    radius: 12,
                  ),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(height: 4),
                        Text(
                          addLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${files.length}/$max foto terpilih',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
            ),
          ),
      ],
    );
  }
}

/// Dashed rounded rectangle border (playful "dropzone" — SRS §7 playful tone).
class DashedRoundedPainter extends CustomPainter {
  const DashedRoundedPainter({required this.color, this.radius = 16, this.strokeWidth = 1.4});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}

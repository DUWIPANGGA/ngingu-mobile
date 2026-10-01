import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/image_helper.dart';

/// Network avatar with initials fallback.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.url,
    required this.name,
    this.radius = 20,
  });

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    if (resolved.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Text(
          _initials(name),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.7,
          ),
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: radius * 2,
          height: radius * 2,
          color: AppColors.softSky,
          child: Icon(Icons.person, size: radius, color: AppColors.primary),
        ),
        errorWidget: (_, _, _) => CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          child: Text(
            _initials(name),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.7,
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

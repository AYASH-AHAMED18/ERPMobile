import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// SpeedCode Labs brand logo.
///
/// The supplied artwork already contains the complete wordmark, so it is
/// rendered as a single asset to keep the brand consistent across platforms.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56, this.plain = false});

  static const _assetPath = 'assets/images/Untitled design (2).png';
  static const _aspectRatio = 762 / 204;

  final double size;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _assetPath,
      height: size,
      width: size * _aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'SpeedCode Labs',
    );

    if (plain) return image;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.11,
        vertical: size * 0.12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: image,
    );
  }
}

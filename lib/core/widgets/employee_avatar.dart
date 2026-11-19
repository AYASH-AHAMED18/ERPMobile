import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.showStatus = false,
    this.isOnline = false,
    this.borderColor,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool showStatus;
  final bool isOnline;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? foregroundColor;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderColor == null ? 0 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) => Center(
                child: SizedBox(
                  width: size * 0.3,
                  height: size * 0.3,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) => _initialsWidget(),
            )
          : _initialsWidget(),
    );

    if (!showStatus) return avatar;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.backlog,
                shape: BoxShape.circle,
                border: Border.all(color: context.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget() {
    return Text(
      _initials,
      style: TextStyle(
        fontSize: size * 0.34,
        fontWeight: FontWeight.w700,
        color: foregroundColor ?? AppColors.primary,
      ),
    );
  }
}

class EmployeeAvatarGroup extends StatelessWidget {
  const EmployeeAvatarGroup({
    super.key,
    required this.names,
    this.size = 30,
    this.max = 3,
  });

  final List<String> names;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(max).toList();
    final remaining = names.length - visible.length;
    return SizedBox(
      height: size,
      width:
          size +
          (visible.length - 1) * size * 0.66 +
          (remaining > 0 ? size * 0.66 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * size * 0.66,
              child: EmployeeAvatar(
                name: visible[i],
                size: size,
                borderColor: context.surface,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visible.length * size * 0.66,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surface, width: 2),
                ),
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

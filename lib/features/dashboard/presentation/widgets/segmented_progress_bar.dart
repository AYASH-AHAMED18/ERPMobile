import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ProgressSegment {
  const ProgressSegment({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final int value;
}

class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.segments,
    this.height = AppSizes.progressHeight,
  });

  final List<ProgressSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((segment) => segment.value > 0).toList();
    final total = visible.fold<int>(0, (sum, segment) => sum + segment.value);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: total == 0
            ? ColoredBox(color: context.line)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final segment in visible)
                    Expanded(
                      flex: segment.value,
                      child: ColoredBox(color: segment.color),
                    ),
                ],
              ),
      ),
    );
  }
}

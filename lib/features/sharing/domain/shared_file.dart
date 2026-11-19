import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

enum FileCategory {
  all('All files', Icons.folder_outlined, AppColors.primary),
  documents('Documents', Icons.description_outlined, AppColors.info),
  spreadsheets('Spreadsheets', Icons.table_chart_outlined, AppColors.success),
  images('Images', Icons.image_outlined, AppColors.review),
  presentations('Presentations', Icons.slideshow_outlined, AppColors.warning),
  other('Other', Icons.insert_drive_file_outlined, AppColors.backlog);

  const FileCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class SharedFile {
  const SharedFile({
    required this.id,
    required this.name,
    required this.category,
    required this.sizeLabel,
    required this.uploadedAt,
    required this.owner,
    required this.url,
    this.allowDownload = true,
    this.description = '',
  });

  final String id;
  final String name;
  final FileCategory category;
  final String sizeLabel;
  final DateTime uploadedAt;
  final String owner;
  final String url;
  final bool allowDownload;
  final String description;

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  factory SharedFile.fromJson(Map<String, dynamic> json) => SharedFile(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? 'File').toString(),
    category: FileCategory.values.firstWhere(
      (category) => category.name == json['category'],
      orElse: () => FileCategory.other,
    ),
    sizeLabel: (json['size'] ?? 'Unknown').toString(),
    uploadedAt:
        DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ??
        DateTime.now(),
    owner: (json['owner'] ?? 'Shared').toString(),
    url: (json['url'] ?? '').toString(),
    allowDownload: json['allow_download'] != false,
    description: (json['description'] ?? '').toString(),
  );
}

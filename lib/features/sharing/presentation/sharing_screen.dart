import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/shared_file.dart';
import 'sharing_controller.dart';

class SharingScreen extends ConsumerStatefulWidget {
  const SharingScreen({super.key});

  @override
  ConsumerState<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends ConsumerState<SharingScreen> {
  final _searchController = TextEditingController();
  FileCategory _category = FileCategory.all;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SharedFile> _filtered(List<SharedFile> files) {
    var items = List<SharedFile>.from(files);
    if (_category != FileCategory.all) {
      items = items.where((file) => file.category == _category).toList();
    }
    if (_search.trim().isNotEmpty) {
      final query = _search.toLowerCase();
      items = items
          .where(
            (file) =>
                file.name.toLowerCase().contains(query) ||
                file.owner.toLowerCase().contains(query) ||
                file.description.toLowerCase().contains(query),
          )
          .toList();
    }
    items.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(sharingControllerProvider);
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sharing'),
            Text(
              'Team documents and files',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh files',
            onPressed: () =>
                ref.read(sharingControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: filesAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading shared files...'),
        error: (error, _) => AppErrorWidget(
          message: 'Unable to load shared files.',
          onRetry: () => ref.read(sharingControllerProvider.notifier).refresh(),
        ),
        data: (files) {
          final filtered = _filtered(files);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Column(
                  children: [
                    AppSearchField(
                      controller: _searchController,
                      hint: 'Search files, owners or content',
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: FileCategory.values
                            .map(
                              (category) => AppFilterChip(
                                label: category.label,
                                color: category.color,
                                count: category == FileCategory.all
                                    ? files.length
                                    : files
                                          .where(
                                            (file) => file.category == category,
                                          )
                                          .length,
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${filtered.length} file${filtered.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Permission-based access',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        title: 'No files found',
                        message:
                            'Try another category or search term. Shared files will appear here.',
                        icon: Icons.folder_open_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = filtered[index];
                          return _FileCard(
                            file: file,
                            onTap: () => _showDetails(context, file),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, SharedFile file) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: file.category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    file.category.icon,
                    size: 21,
                    color: file.category.color,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatusBadge(
                  label: file.extension,
                  color: file.category.color,
                  compact: true,
                ),
                const SizedBox(width: 6),
                StatusBadge(
                  label: file.category.label,
                  color: file.category.color,
                  compact: true,
                ),
                const Spacer(),
                Text(
                  file.sizeLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            if (file.description.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                file.description,
                style: const TextStyle(fontSize: 12.5, height: 1.55),
              ),
            ],
            const Divider(height: 24),
            _FileInfoRow(
              label: 'Owner',
              value: file.owner,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 8),
            _FileInfoRow(
              label: 'Uploaded',
              value: dates.AppDate.full(file.uploadedAt),
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _download(context, file),
                icon: Icon(
                  file.allowDownload
                      ? Icons.download_rounded
                      : Icons.lock_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  file.allowDownload ? 'Download file' : 'Download restricted',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, SharedFile file) async {
    if (!file.allowDownload) {
      showAppSnackBar(
        context,
        'You do not have permission to download this file.',
        isError: true,
      );
      return;
    }
    if (AppConfig.useMockData) {
      showAppSnackBar(
        context,
        'Demo file. Connect the ERP backend to enable downloads.',
      );
      return;
    }
    final uri = Uri.tryParse(file.url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!context.mounted) return;
    if (!opened) {
      showAppSnackBar(context, 'The file could not be opened.', isError: true);
    }
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.file, required this.onTap});

  final SharedFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: file.category.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      file.category.icon,
                      size: 20,
                      color: file.category.color,
                    ),
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: file.category.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          file.extension,
                          style: const TextStyle(
                            fontSize: 5.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${file.owner} • ${dates.AppDate.relativeTime(file.uploadedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          file.sizeLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!file.allowDownload)
                          const Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 9,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Restricted',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileInfoRow extends StatelessWidget {
  const _FileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

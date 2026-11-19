import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/meeting.dart';
import 'live_controller.dart';

enum _MeetingFilter { upcoming, live, past }

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  _MeetingFilter _filter = _MeetingFilter.upcoming;

  List<Meeting> _filtered(List<Meeting> meetings) {
    switch (_filter) {
      case _MeetingFilter.live:
        return meetings
            .where((meeting) => meeting.status == MeetingStatus.live)
            .toList();
      case _MeetingFilter.upcoming:
        return meetings
            .where((meeting) => meeting.status == MeetingStatus.upcoming)
            .toList();
      case _MeetingFilter.past:
        return meetings
            .where(
              (meeting) =>
                  meeting.status == MeetingStatus.completed ||
                  meeting.status == MeetingStatus.cancelled,
            )
            .toList();
    }
  }

  int _count(List<Meeting> meetings, MeetingStatus status) =>
      meetings.where((meeting) => meeting.status == status).length;

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(liveControllerProvider);
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live meetings'),
            Text(
              'Catch up with your team',
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
            tooltip: 'Refresh meetings',
            onPressed: () =>
                ref.read(liveControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: meetingsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading meetings...'),
        error: (error, _) => AppErrorWidget(
          message: 'Unable to load meetings.',
          onRetry: () => ref.read(liveControllerProvider.notifier).refresh(),
        ),
        data: (meetings) {
          final items = _filtered(meetings);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppFilterChip(
                        label: 'Upcoming',
                        count: _count(meetings, MeetingStatus.upcoming),
                        selected: _filter == _MeetingFilter.upcoming,
                        onSelected: (_) =>
                            setState(() => _filter = _MeetingFilter.upcoming),
                      ),
                      AppFilterChip(
                        label: 'Live now',
                        color: AppColors.error,
                        count: _count(meetings, MeetingStatus.live),
                        selected: _filter == _MeetingFilter.live,
                        onSelected: (_) =>
                            setState(() => _filter = _MeetingFilter.live),
                      ),
                      AppFilterChip(
                        label: 'History',
                        color: AppColors.backlog,
                        count: meetings
                            .where(
                              (meeting) =>
                                  meeting.status == MeetingStatus.completed ||
                                  meeting.status == MeetingStatus.cancelled,
                            )
                            .length,
                        selected: _filter == _MeetingFilter.past,
                        onSelected: (_) =>
                            setState(() => _filter = _MeetingFilter.past),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: items.isEmpty
                    ? AppEmptyState(
                        title: _filter == _MeetingFilter.live
                            ? 'No active meetings'
                            : _filter == _MeetingFilter.past
                            ? 'No meeting history'
                            : 'No upcoming meetings',
                        message: _filter == _MeetingFilter.live
                            ? 'Meetings that are happening now will appear here.'
                            : 'Your scheduled meetings will appear here.',
                        icon: Icons.videocam_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _MeetingCard(
                          meeting: items[index],
                          onJoin: () => _join(context, items[index]),
                          onDetails: () => _details(context, items[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _join(BuildContext context, Meeting meeting) async {
    if (meeting.status == MeetingStatus.completed ||
        meeting.status == MeetingStatus.cancelled) {
      _details(context, meeting);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          meeting.status == MeetingStatus.live
              ? 'Join live meeting?'
              : 'Open meeting link?',
        ),
        content: Text(
          '${meeting.title}\nHosted by ${meeting.host}\n'
          '${dates.AppDate.full(meeting.startsAt)} • ${dates.AppDate.time(meeting.startsAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final uri = Uri.tryParse(meeting.meetingUrl ?? '');
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        'No meeting link is available. Contact the meeting host.',
        isError: true,
      );
    }
  }

  void _details(BuildContext context, Meeting meeting) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(
                  label: meeting.status.label,
                  color: meeting.status.color,
                ),
                const SizedBox(width: 7),
                if (meeting.isExternal)
                  const StatusBadge(
                    label: 'External',
                    color: AppColors.info,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meeting.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'Hosted by ${meeting.host}',
              style: TextStyle(fontSize: 11.5, color: context.textSecondary),
            ),
            const Divider(height: 24),
            Text(
              meeting.description,
              style: const TextStyle(fontSize: 12.5, height: 1.6),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: dates.AppDate.full(meeting.startsAt),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text:
                  '${dates.AppDate.time(meeting.startsAt)} - ${dates.AppDate.time(meeting.endsAt)}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.groups_outlined,
              text: '${meeting.attendees} attendees',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _join(pageContext, meeting);
                },
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: Text(
                  meeting.status == MeetingStatus.live
                      ? 'Join now'
                      : 'Open meeting',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({
    required this.meeting,
    required this.onJoin,
    required this.onDetails,
  });

  final Meeting meeting;
  final VoidCallback onJoin;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final isLive = meeting.status == MeetingStatus.live;
    final color = isLive ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isLive ? AppColors.error.withValues(alpha: 0.3) : context.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      dates.AppDate.relativeDate(
                        meeting.startsAt,
                      ).split(' ')[0],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      dates.AppDate.relativeDate(
                        meeting.startsAt,
                      ).split(' ')[1],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dates.AppDate.shortTime(meeting.startsAt),
                      style: TextStyle(
                        fontSize: 8.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          label: meeting.status.label,
                          color: meeting.status.color,
                          compact: true,
                        ),
                        if (meeting.isExternal) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 11,
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meeting.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Host: ${meeting.host} • ${meeting.attendees} attendees',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            meeting.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Details', style: TextStyle(fontSize: 11.5)),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: isLive
                        ? AppColors.error
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: Icon(
                    isLive ? Icons.videocam_rounded : Icons.open_in_new_rounded,
                    size: 15,
                  ),
                  label: Text(
                    isLive ? 'Join now' : 'Open link',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.5, color: context.textPrimary),
          ),
        ),
      ],
    );
  }
}

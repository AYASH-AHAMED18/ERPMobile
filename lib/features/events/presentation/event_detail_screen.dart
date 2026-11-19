import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../calendar/presentation/calendar_controller.dart';
import '../domain/company_event.dart';
import 'events_controller.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _addingToCalendar = false;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsControllerProvider);
    CompanyEvent? selected;
    for (final item in events.value ?? const <CompanyEvent>[]) {
      if (item.id == widget.eventId) {
        selected = item;
        break;
      }
    }
    return ErpModuleScaffold(
      body: events.when(
        loading: () => const AppLoadingIndicator(message: 'Loading event...'),
        error: (error, _) => AppErrorWidget(
          message: 'This event could not be loaded.',
          onRetry: () => ref.read(eventsControllerProvider.notifier).refresh(),
        ),
        data: (_) {
          final event = selected;
          if (event == null) {
            return Column(
              children: [
                AppPageTitle(
                  title: 'Event details',
                  subtitle: 'Company event',
                  onBack: () => context.pop(),
                ),
                const Expanded(
                  child: AppEmptyState(
                    title: 'Event not found',
                    message: 'This event may have been removed.',
                    icon: Icons.event_busy_outlined,
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(eventsControllerProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 26),
              children: [
                AppPageTitle(
                  title: 'Event details',
                  subtitle: event.category.label,
                  onBack: () => context.pop(),
                  trailing: IconButton(
                    tooltip: 'Share event',
                    onPressed: () => _share(event),
                    icon: const Icon(Icons.share_outlined, size: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EventBanner(event: event),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusBadge(
                            label: event.category.label,
                            color: event.category.color,
                          ),
                          StatusBadge(
                            label: event.status.label,
                            color: event.status.color,
                          ),
                          if (event.registered)
                            const StatusBadge(
                              label: 'Registered',
                              color: AppColors.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat(
                          'EEEE, dd MMMM yyyy',
                        ).format(event.date),
                      ),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Time',
                        value: event.startTime == null
                            ? 'Time to be confirmed'
                            : '${event.startTime}${event.endTime == null ? '' : ' - ${event.endTime}'}',
                      ),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Venue',
                        value: event.location ?? 'To be confirmed',
                        action: event.location == null
                            ? null
                            : TextButton(
                                onPressed: () => _openLocation(event),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 28),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                ),
                                child: const Text(
                                  'View location',
                                  style: TextStyle(fontSize: 10.5),
                                ),
                              ),
                      ),
                      _InfoRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Participants',
                        value: '${event.participantCount} attending',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Add to calendar',
                              icon: Icons.event_available_rounded,
                              loading: _addingToCalendar,
                              onPressed: event.status == EventStatus.cancelled
                                  ? null
                                  : () => _addToCalendar(event),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => _share(event),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(46, 46),
                              ),
                              child: const Icon(Icons.share_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              size: 17,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'About this event',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description.isEmpty
                              ? 'No event description has been provided.'
                              : event.description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (event.organizer != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      child: Row(
                        children: [
                          EmployeeAvatar(name: event.organizer!, size: 42),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.organizer!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  event.organizerDepartment ??
                                      'Event organizer',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const StatusBadge(
                            label: 'Organizer',
                            color: AppColors.primary,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (event.instructions != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _NoteCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Things to know',
                      message: event.instructions!,
                      color: AppColors.info,
                    ),
                  ),
                ],
                if (event.registrationEnabled && !event.registered) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _NoteCard(
                      icon: Icons.how_to_reg_outlined,
                      title: 'Registration is open',
                      message:
                          'Registration for this event is managed by ${event.organizer ?? 'the event organizer'}. Contact the organizer or HR to reserve your place.',
                      color: AppColors.warning,
                    ),
                  ),
                ],
                if (event.participants.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                size: 17,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Attendees (${event.participantCount})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...event.participants.map(
                            (participant) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  EmployeeAvatar(
                                    name: participant.name,
                                    imageUrl: participant.avatarUrl,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      participant.name,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    participant.department,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToCalendar(CompanyEvent event) async {
    setState(() => _addingToCalendar = true);
    try {
      await ref
          .read(calendarControllerProvider.notifier)
          .create(
            CalendarEvent(
              id: 'event-${DateTime.now().millisecondsSinceEpoch}',
              title: event.title,
              date: event.date,
              type: CalendarEventType.company,
              description: event.description,
              startTime: event.startTime,
              endTime: event.endTime,
              location: event.location,
              createdByMe: true,
            ),
          );
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Event added to your calendar.',
        isSuccess: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Event could not be added to your calendar.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _addingToCalendar = false);
    }
  }

  Future<void> _share(CompanyEvent event) async {
    final text =
        '${event.title}\n'
        '${DateFormat('EEEE, dd MMMM yyyy').format(event.date)}'
        '${event.startTime == null ? '' : ' at ${event.startTime}'}\n'
        '${event.location ?? 'Location to be confirmed'}\n\n'
        '${event.description}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(context, 'Event details copied to clipboard.');
  }

  Future<void> _openLocation(CompanyEvent event) async {
    final location = event.location;
    if (location == null) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      showAppSnackBar(
        context,
        'Maps could not be opened on this device.',
        isError: true,
      );
    }
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.event});

  final CompanyEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            event.category.color,
            event.category.color.withValues(alpha: 0.72),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (event.bannerUrl != null && event.bannerUrl!.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: event.bannerUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              event.category.icon,
              size: 150,
              color: Colors.white.withValues(alpha: 0.17),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: StatusBadge(
              label: event.status.label,
              color: Colors.white,
              icon: event.status.icon,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(fontSize: 10.5, color: context.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

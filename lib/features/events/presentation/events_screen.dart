import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/company_event.dart';
import 'events_controller.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();
  EventCategory? _category;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CompanyEvent> _filtered(List<CompanyEvent> events) {
    var items = List<CompanyEvent>.from(events);
    if (_category != null) {
      items = items.where((event) => event.category == _category).toList();
    }
    if (_search.trim().isNotEmpty) {
      final query = _search.toLowerCase();
      items = items
          .where(
            (event) =>
                event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                (event.location ?? '').toLowerCase().contains(query),
          )
          .toList();
    }
    items.sort((a, b) {
      final aUpcoming =
          a.status == EventStatus.upcoming || a.status == EventStatus.ongoing;
      final bUpcoming =
          b.status == EventStatus.upcoming || b.status == EventStatus.ongoing;
      if (aUpcoming != bUpcoming) return aUpcoming ? -1 : 1;
      return a.startsAt.compareTo(b.startsAt);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsControllerProvider);
    return ErpModuleScaffold(
      body: events.when(
        loading: () => const AppLoadingIndicator(message: 'Loading events...'),
        error: (error, _) => AppErrorWidget(
          message: 'Company events could not be loaded.',
          onRetry: () => ref.read(eventsControllerProvider.notifier).refresh(),
        ),
        data: (allEvents) {
          final items = _filtered(allEvents);
          CompanyEvent? featured;
          if (_search.isEmpty && _category == null) {
            for (final event in items) {
              if (event.status == EventStatus.upcoming ||
                  event.status == EventStatus.ongoing) {
                featured = event;
                break;
              }
            }
          }
          final featuredEvent = featured;
          final listItems = featuredEvent == null
              ? items
              : items.where((event) => event.id != featuredEvent.id).toList();
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(eventsControllerProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const AppPageTitle(
                  title: 'Events',
                  subtitle: 'Company events, workshops and celebrations',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppSearchField(
                    controller: _searchController,
                    hint: 'Search events, venues, activities',
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ModuleFilterRow(
                    children: [
                      AppFilterChip(
                        label: 'All events',
                        count: allEvents.length,
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      ...EventCategory.values.map(
                        (category) => AppFilterChip(
                          label: category.label,
                          color: category.color,
                          selected: _category == category,
                          onSelected: (_) => setState(
                            () => _category = _category == category
                                ? null
                                : category,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (featuredEvent != null) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FeaturedEventCard(
                      event: featuredEvent,
                      onTap: () =>
                          context.push('/more/events/${featuredEvent.id}'),
                    ),
                  ),
                ],
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: AppEmptyState(
                      title: 'No events found',
                      message:
                          'Try a different search or category to find company events.',
                      icon: Icons.event_busy_outlined,
                    ),
                  )
                else ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ModuleSectionTitle(
                      title: 'All events',
                      subtitle:
                          '${items.length} event${items.length == 1 ? '' : 's'} in the company calendar',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...listItems.map(
                    (event) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                      child: _EventCard(
                        event: event,
                        onTap: () => context.push('/more/events/${event.id}'),
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
}

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard({required this.event, required this.onTap});

  final CompanyEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
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
              if (event.bannerUrl != null && event.bannerUrl!.isNotEmpty)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -28,
                top: -32,
                child: Icon(
                  event.category.icon,
                  size: 170,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          label: event.category.label,
                          color: Colors.white,
                          compact: true,
                        ),
                        const Spacer(),
                        StatusBadge(
                          label: event.status.label,
                          color: event.status == EventStatus.ongoing
                              ? AppColors.success
                              : Colors.white,
                          compact: true,
                          filled: event.status == EventStatus.ongoing,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('EEEE, dd MMMM').format(event.date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _timeLabel(event),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.location ?? 'Location to be confirmed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (event.participants.isNotEmpty)
                          EmployeeAvatarGroup(
                            names: event.participants
                                .map((participant) => participant.name)
                                .toList(),
                            size: 26,
                          ),
                        const Spacer(),
                        const Text(
                          'View details',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final CompanyEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(event.date).toUpperCase();
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: event.category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: event.category.color,
                        ),
                      ),
                      Text(
                        '${event.date.day}',
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: event.category.color,
                        ),
                      ),
                      Text(
                        DateFormat('EEE').format(event.date),
                        style: TextStyle(
                          fontSize: 9,
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
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(
                            label: event.status.label,
                            color: event.status.color,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: context.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _timeLabel(event),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: context.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location ?? 'Location to be confirmed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          StatusBadge(
                            label: event.category.label,
                            color: event.category.color,
                            compact: true,
                          ),
                          const Spacer(),
                          if (event.registrationEnabled)
                            Text(
                              event.registered
                                  ? 'Registered'
                                  : 'Registration open',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: event.registered
                                    ? AppColors.success
                                    : AppColors.info,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _timeLabel(CompanyEvent event) {
  if (event.startTime == null) return dates.AppDate.shortDate(event.date);
  final end = event.endTime == null ? '' : ' - ${event.endTime}';
  return '${event.startTime}$end';
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_repository.dart';
import '../domain/calendar_event.dart';

class CalendarController extends AsyncNotifier<List<CalendarEvent>> {
  @override
  Future<List<CalendarEvent>> build() {
    final now = DateTime.now();
    final from = DateTime(now.year - 1, 1, 1);
    final to = DateTime(now.year + 1, 12, 31);
    return ref
        .watch(calendarRepositoryProvider)
        .fetchEvents(from: from, to: to);
  }

  Future<void> refresh() async {
    final now = DateTime.now();
    state = const AsyncLoading<List<CalendarEvent>>();
    state = await AsyncValue.guard(
      () => ref
          .read(calendarRepositoryProvider)
          .fetchEvents(
            from: DateTime(now.year - 1, 1, 1),
            to: DateTime(now.year + 1, 12, 31),
          ),
    );
  }

  Future<CalendarEvent> create(CalendarEvent event) async {
    final created = await ref
        .read(calendarRepositoryProvider)
        .createEvent(event);
    await refresh();
    return created;
  }
}

final calendarControllerProvider =
    AsyncNotifierProvider<CalendarController, List<CalendarEvent>>(
      CalendarController.new,
    );

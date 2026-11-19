import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> fetchEvents({
    required DateTime from,
    required DateTime to,
  });

  Future<CalendarEvent> createEvent(CalendarEvent event);
}

class MockCalendarRepository implements CalendarRepository {
  MockCalendarRepository(this._db);
  final MockDatabase _db;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _db.events
        .where(
          (event) =>
              !event.date.isBefore(from) &&
              event.date.isBefore(to.add(const Duration(days: 1))),
        )
        .toList();
  }

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _db.events.add(event);
    return event;
  }
}

class ApiCalendarRepository implements CalendarRepository {
  ApiCalendarRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _client.get(
      ApiEndpoints.calendarEvents,
      query: {'from': from.toIso8601String(), 'to': to.toIso8601String()},
    );
    return asList(
      data,
    ).map((item) => CalendarEvent.fromJson(mapOf(item))).toList();
  }

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final data = await _client.post(
      ApiEndpoints.calendarEvents,
      data: {
        'title': event.title,
        'date': event.date.toIso8601String(),
        'type': event.type.name,
        'description': event.description,
        'start_time': event.startTime,
        'end_time': event.endTime,
        'location': event.location,
      },
    );
    return CalendarEvent.fromJson(asMap(data));
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockCalendarRepository(MockDatabase.instance);
  }
  return ApiCalendarRepository(ref.watch(apiClientProvider));
});

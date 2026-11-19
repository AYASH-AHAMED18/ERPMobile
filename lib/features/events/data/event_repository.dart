import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/company_event.dart';

abstract class EventRepository {
  Future<List<CompanyEvent>> fetchEvents({String? search});
}

class MockEventRepository implements EventRepository {
  MockEventRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<CompanyEvent>> fetchEvents({String? search}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    var items = List<CompanyEvent>.from(_db.companyEvents);
    if (search != null && search.trim().isNotEmpty) {
      final query = search.toLowerCase();
      items = items
          .where(
            (event) =>
                event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                (event.location ?? '').toLowerCase().contains(query) ||
                event.category.label.toLowerCase().contains(query),
          )
          .toList();
    }
    items.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return items;
  }
}

class ApiEventRepository implements EventRepository {
  ApiEventRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CompanyEvent>> fetchEvents({String? search}) async {
    final now = DateTime.now();
    final data = await _client.get(
      ApiEndpoints.calendarEvents,
      query: {
        'from': DateTime(now.year - 1, 1, 1).toIso8601String(),
        'to': DateTime(now.year + 2, 12, 31).toIso8601String(),
      },
    );
    final items = <CompanyEvent>[];
    for (final raw in asList(data)) {
      final map = mapOf(raw);
      final type = (map['type'] ?? '').toString().toLowerCase();
      if (type == 'holiday' ||
          type == 'leave' ||
          type == 'working_day' ||
          type == 'project_deadline') {
        continue;
      }
      final event = CompanyEvent.fromJson(map);
      if (search != null &&
          search.trim().isNotEmpty &&
          !event.title.toLowerCase().contains(search.toLowerCase()) &&
          !event.description.toLowerCase().contains(search.toLowerCase())) {
        continue;
      }
      items.add(event);
    }
    items.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return items;
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockEventRepository(MockDatabase.instance);
  }
  return ApiEventRepository(ref.watch(apiClientProvider));
});

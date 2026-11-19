import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/meeting.dart';

abstract class LiveRepository {
  Future<List<Meeting>> fetchMeetings();
}

class MockLiveRepository implements LiveRepository {
  MockLiveRepository(this._db);
  final MockDatabase _db;

  @override
  Future<List<Meeting>> fetchMeetings() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_db.meetings);
  }
}

class ApiLiveRepository implements LiveRepository {
  ApiLiveRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Meeting>> fetchMeetings() async {
    final data = await _client.get(ApiEndpoints.meetings);
    return asList(data).map((item) => Meeting.fromJson(mapOf(item))).toList();
  }
}

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockLiveRepository(MockDatabase.instance);
  }
  return ApiLiveRepository(ref.watch(apiClientProvider));
});

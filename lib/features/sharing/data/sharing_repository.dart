import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/shared_file.dart';

abstract class SharingRepository {
  Future<List<SharedFile>> fetchFiles({FileCategory? category, String? search});
}

class MockSharingRepository implements SharingRepository {
  MockSharingRepository(this._db);
  final MockDatabase _db;

  @override
  Future<List<SharedFile>> fetchFiles({
    FileCategory? category,
    String? search,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    var files = List<SharedFile>.from(_db.sharedFiles);
    if (category != null && category != FileCategory.all) {
      files = files.where((file) => file.category == category).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final query = search.toLowerCase();
      files = files
          .where(
            (file) =>
                file.name.toLowerCase().contains(query) ||
                file.owner.toLowerCase().contains(query),
          )
          .toList();
    }
    return files;
  }
}

class ApiSharingRepository implements SharingRepository {
  ApiSharingRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<SharedFile>> fetchFiles({
    FileCategory? category,
    String? search,
  }) async {
    final data = await _client.get(
      ApiEndpoints.sharedFiles,
      query: {
        if (category != null && category != FileCategory.all)
          'category': category.name,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return asList(
      data,
    ).map((item) => SharedFile.fromJson(mapOf(item))).toList();
  }
}

final sharingRepositoryProvider = Provider<SharingRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockSharingRepository(MockDatabase.instance);
  }
  return ApiSharingRepository(ref.watch(apiClientProvider));
});

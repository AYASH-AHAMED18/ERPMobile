import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sharing_repository.dart';
import '../domain/shared_file.dart';

class SharingController extends AsyncNotifier<List<SharedFile>> {
  @override
  Future<List<SharedFile>> build() {
    return ref.watch(sharingRepositoryProvider).fetchFiles();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<SharedFile>>();
    state = await AsyncValue.guard(
      () => ref.read(sharingRepositoryProvider).fetchFiles(),
    );
  }
}

final sharingControllerProvider =
    AsyncNotifierProvider<SharingController, List<SharedFile>>(
      SharingController.new,
    );

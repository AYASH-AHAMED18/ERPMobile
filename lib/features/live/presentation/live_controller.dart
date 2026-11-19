import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/live_repository.dart';
import '../domain/meeting.dart';

class LiveController extends AsyncNotifier<List<Meeting>> {
  @override
  Future<List<Meeting>> build() {
    return ref.watch(liveRepositoryProvider).fetchMeetings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Meeting>>();
    state = await AsyncValue.guard(
      () => ref.read(liveRepositoryProvider).fetchMeetings(),
    );
  }
}

final liveControllerProvider =
    AsyncNotifierProvider<LiveController, List<Meeting>>(LiveController.new);

final liveMeetingsProvider = Provider<AsyncValue<List<Meeting>>>((ref) {
  return ref.watch(liveControllerProvider);
});

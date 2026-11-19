import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/summary_repository.dart';
import '../domain/summary.dart';

class SummaryController extends AsyncNotifier<SummaryData> {
  @override
  Future<SummaryData> build() {
    return ref.watch(summaryRepositoryProvider).fetchSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<SummaryData>();
    state = await AsyncValue.guard(
      () => ref.read(summaryRepositoryProvider).fetchSummary(),
    );
  }
}

final summaryControllerProvider =
    AsyncNotifierProvider<SummaryController, SummaryData>(
      SummaryController.new,
    );

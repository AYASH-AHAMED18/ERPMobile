import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository.dart';
import '../domain/company_event.dart';

class EventsController extends AsyncNotifier<List<CompanyEvent>> {
  @override
  Future<List<CompanyEvent>> build() {
    return ref.watch(eventRepositoryProvider).fetchEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<CompanyEvent>>();
    state = await AsyncValue.guard(
      () => ref.read(eventRepositoryProvider).fetchEvents(),
    );
  }

  Future<void> search(String query) async {
    state = const AsyncLoading<List<CompanyEvent>>();
    state = await AsyncValue.guard(
      () => ref.read(eventRepositoryProvider).fetchEvents(search: query),
    );
  }
}

final eventsControllerProvider =
    AsyncNotifierProvider<EventsController, List<CompanyEvent>>(
      EventsController.new,
    );

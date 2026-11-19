import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_repository.dart';
import '../domain/project.dart';

class ProjectsController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() {
    return ref.watch(projectRepositoryProvider).fetchProjects();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Project>>();
    state = await AsyncValue.guard(
      () => ref.read(projectRepositoryProvider).fetchProjects(),
    );
  }
}

final projectsControllerProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );

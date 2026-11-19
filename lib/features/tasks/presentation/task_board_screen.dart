import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/task.dart';
import 'task_controllers.dart';
import 'widgets/task_cards.dart';

enum TaskScope { all, mine, assigned }

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  final _searchController = TextEditingController();
  TaskScope _scope = TaskScope.all;
  TaskStatus? _status;
  TaskPriority? _priority;
  String _search = '';
  bool _kanban = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TaskItem> _filter(List<TaskItem> tasks, {bool ignoreStatus = false}) {
    var items = List<TaskItem>.from(tasks);
    switch (_scope) {
      case TaskScope.mine:
        items = items.where((task) => task.assignedToMe).toList();
        break;
      case TaskScope.assigned:
        items = items.where((task) => !task.assignedToMe).toList();
        break;
      case TaskScope.all:
        break;
    }
    if (_priority != null) {
      items = items.where((task) => task.priority == _priority).toList();
    }
    if (!ignoreStatus && _status != null) {
      items = items.where((task) => task.status == _status).toList();
    }
    if (_search.trim().isNotEmpty) {
      final query = _search.toLowerCase();
      items = items
          .where(
            (task) =>
                task.title.toLowerCase().contains(query) ||
                task.projectName.toLowerCase().contains(query) ||
                task.assignee.name.toLowerCase().contains(query) ||
                task.description.toLowerCase().contains(query),
          )
          .toList();
    }
    items.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return a.dueDate.compareTo(b.dueDate);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskBoardControllerProvider);
    return ErpModuleScaffold(
      body: tasks.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading your task board...'),
        error: (error, _) => AppErrorWidget(
          message: 'We could not load tasks. Pull to refresh or try again.',
          onRetry: () =>
              ref.read(taskBoardControllerProvider.notifier).refresh(),
        ),
        data: (allTasks) {
          final scoped = _filter(allTasks, ignoreStatus: true);
          final visible = _filter(allTasks);
          return Column(
            children: [
              AppPageTitle(
                title: 'My Tasks',
                subtitle: 'Plan, track and deliver project work',
                trailing: IconButton(
                  tooltip: 'Refresh tasks',
                  onPressed: () =>
                      ref.read(taskBoardControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            controller: _searchController,
                            hint: 'Search tasks, projects, people',
                            onChanged: (value) =>
                                setState(() => _search = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ViewToggle(
                          kanban: _kanban,
                          onChanged: (value) => setState(() => _kanban = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          AppFilterChip(
                            label: 'All tasks',
                            count: allTasks.length,
                            selected: _scope == TaskScope.all,
                            onSelected: (_) =>
                                setState(() => _scope = TaskScope.all),
                          ),
                          AppFilterChip(
                            label: 'My tasks',
                            count: allTasks
                                .where((task) => task.assignedToMe)
                                .length,
                            selected: _scope == TaskScope.mine,
                            onSelected: (_) =>
                                setState(() => _scope = TaskScope.mine),
                          ),
                          AppFilterChip(
                            label: 'Assigned',
                            count: allTasks
                                .where((task) => !task.assignedToMe)
                                .length,
                            selected: _scope == TaskScope.assigned,
                            onSelected: (_) =>
                                setState(() => _scope = TaskScope.assigned),
                          ),
                          AppFilterChip(
                            label: _priority == null
                                ? 'Priority'
                                : '${_priority!.label} priority',
                            color: _priority?.color ?? AppColors.review,
                            selected: _priority != null,
                            onSelected: (_) => _pickPriority(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          AppFilterChip(
                            label: 'All status',
                            count: scoped.length,
                            selected: _status == null,
                            onSelected: (_) => setState(() => _status = null),
                          ),
                          ...TaskStatus.values.map(
                            (status) => AppFilterChip(
                              label: status.label,
                              color: status.color,
                              count: scoped
                                  .where((task) => task.status == status)
                                  .length,
                              selected: _status == status,
                              onSelected: (_) => setState(
                                () =>
                                    _status = _status == status ? null : status,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${visible.length} task${visible.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (_status != null ||
                            _priority != null ||
                            _search.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _search = '';
                                _status = null;
                                _priority = null;
                                _scope = TaskScope.all;
                              });
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 28),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Clear filters',
                              style: TextStyle(fontSize: 10.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: visible.isEmpty
                    ? const AppEmptyState(
                        title: 'No tasks found',
                        message:
                            'Try changing filters or search terms to find tasks.',
                        icon: Icons.assignment_outlined,
                      )
                    : _kanban
                    ? _KanbanBoard(tasks: visible)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = visible[index];
                          return TaskListCard(
                            task: task,
                            onTap: () => context.push('/tasks/${task.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickPriority(BuildContext context) async {
    final selection = await showModalBottomSheet<TaskPriority?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filter by priority',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all_rounded, size: 20),
              title: const Text('All priorities'),
              trailing: _priority == null
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
              onTap: () => Navigator.pop(context, null),
            ),
            ...TaskPriority.values.map(
              (priority) => ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: priority.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text('${priority.label} priority'),
                trailing: _priority == priority
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.pop(context, priority),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    setState(() => _priority = selection);
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.kanban, required this.onChanged});

  final bool kanban;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          _ToggleButton(
            icon: Icons.view_agenda_outlined,
            active: !kanban,
            tooltip: 'List view',
            onTap: () => onChanged(false),
          ),
          _ToggleButton(
            icon: Icons.view_kanban_outlined,
            active: kanban,
            tooltip: 'Kanban view',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final statuses = TaskStatus.values
        .where((status) => tasks.any((task) => task.status == status))
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: statuses.map((status) {
              final items = tasks
                  .where((task) => task.status == status)
                  .toList();
              return Container(
                width: 252,
                height: constraints.maxHeight - 26,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${items.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: status.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = items[index];
                          return TaskKanbanCard(
                            task: task,
                            onTap: () => context.push('/tasks/${task.id}'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

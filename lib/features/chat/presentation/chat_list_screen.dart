import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/chat.dart';
import 'chat_controllers.dart';

enum _ChatFilter { all, unread, groups }

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  _ChatFilter _filter = _ChatFilter.all;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filtered(List<Conversation> conversations) {
    var items = List<Conversation>.from(conversations);
    switch (_filter) {
      case _ChatFilter.unread:
        items = items
            .where((conversation) => conversation.unreadCount > 0)
            .toList();
        break;
      case _ChatFilter.groups:
        items = items.where((conversation) => conversation.isGroup).toList();
        break;
      case _ChatFilter.all:
        break;
    }
    if (_search.trim().isNotEmpty) {
      final query = _search.toLowerCase();
      items = items
          .where(
            (conversation) =>
                conversation.title.toLowerCase().contains(query) ||
                conversation.lastMessage.toLowerCase().contains(query),
          )
          .toList();
    }
    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsControllerProvider);
    final totalUnread =
        conversations.value?.fold<int>(
          0,
          (sum, item) => sum + item.unreadCount,
        ) ??
        0;

    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Chat'),
                if (totalUnread > 0) ...[
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: '$totalUnread unread',
                    color: AppColors.primary,
                    compact: true,
                  ),
                ],
              ],
            ),
            Text(
              'Team communication',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh conversations',
            onPressed: () =>
                ref.read(conversationsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: conversations.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading conversations...'),
        error: (error, _) => AppErrorWidget(
          message: 'We could not load your conversations.',
          onRetry: () =>
              ref.read(conversationsControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          final filtered = _filtered(items);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Column(
                  children: [
                    AppSearchField(
                      controller: _searchController,
                      hint: 'Search people and conversations',
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          AppFilterChip(
                            label: 'All',
                            count: items.length,
                            selected: _filter == _ChatFilter.all,
                            onSelected: (_) =>
                                setState(() => _filter = _ChatFilter.all),
                          ),
                          AppFilterChip(
                            label: 'Unread',
                            count: items
                                .where((item) => item.unreadCount > 0)
                                .length,
                            color: AppColors.error,
                            selected: _filter == _ChatFilter.unread,
                            onSelected: (_) =>
                                setState(() => _filter = _ChatFilter.unread),
                          ),
                          AppFilterChip(
                            label: 'Groups',
                            count: items.where((item) => item.isGroup).length,
                            color: AppColors.review,
                            selected: _filter == _ChatFilter.groups,
                            onSelected: (_) =>
                                setState(() => _filter = _ChatFilter.groups),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        title: 'No conversations found',
                        message:
                            'Try another search term or change the filter.',
                        icon: Icons.forum_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conversation = filtered[index];
                          return _ConversationTile(
                            conversation: conversation,
                            onTap: () async {
                              await ref
                                  .read(
                                    conversationsControllerProvider.notifier,
                                  )
                                  .markRead(conversation.id);
                              if (!context.mounted) return;
                              context.push(
                                '/chat/${conversation.id}',
                                extra: conversation,
                              );
                            },
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
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : context.line,
            ),
          ),
          child: Row(
            children: [
              if (conversation.isGroup)
                EmployeeAvatarGroup(
                  names: conversation.participants
                      .map((employee) => employee.name)
                      .toList(),
                  size: 34,
                  max: 2,
                )
              else
                EmployeeAvatar(
                  name: conversation.title,
                  imageUrl: conversation.peer?.avatarUrl,
                  size: 42,
                  showStatus: true,
                  isOnline: conversation.isOnline,
                ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (conversation.pinned) ...[
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeLabel(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: unread
                                ? AppColors.primary
                                : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.isGroup
                                ? conversation.lastMessage
                                : conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: unread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: unread
                                  ? context.textPrimary
                                  : context.textSecondary,
                            ),
                          ),
                        ),
                        if (conversation.isGroup &&
                            conversation.unreadCount > 0)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.mark_chat_unread_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (conversation.isGroup)
                          Text(
                            '${conversation.participants.length + 1} members',
                            style: TextStyle(
                              fontSize: 9,
                              color: context.textSecondary,
                            ),
                          )
                        else
                          Text(
                            conversation.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: conversation.isOnline
                                  ? AppColors.success
                                  : context.textSecondary,
                            ),
                          ),
                        const Spacer(),
                        CountBadge(count: conversation.unreadCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime value) {
    if (dates.AppDate.isSameDay(value, DateTime.now())) {
      return dates.AppDate.messageTime(value);
    }
    return dates.AppDate.relativeDate(value);
  }
}

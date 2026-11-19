import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../domain/chat.dart';
import 'chat_controllers.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  final String conversationId;
  final Conversation? conversation;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Conversation? get _conversation {
    if (widget.conversation != null) return widget.conversation;
    final conversations =
        ref.read(conversationsControllerProvider).value ?? const [];
    for (final conversation in conversations) {
      if (conversation.id == widget.conversationId) return conversation;
    }
    return null;
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(conversationControllerProvider(widget.conversationId).notifier)
          .send(text);
      _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Message could not be sent.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAttachment() async {
    final type = await showModalBottomSheet<String>(
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
                  'Attach to message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.review,
              ),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_outlined,
                color: AppColors.info,
              ),
              title: const Text('Document or file'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;

    ChatAttachment? attachment;
    try {
      if (type == 'gallery') {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 82,
        );
        if (picked != null) {
          attachment = ChatAttachment(
            name: picked.name,
            url: picked.path,
            size: 'Image',
            isImage: true,
          );
        }
      } else {
        final files = await FilePicker.pickFiles();
        final file = files.isEmpty ? null : files.first;
        if (file != null) {
          final bytes = file.lengthSync() ?? 0;
          attachment = ChatAttachment(
            name: file.name,
            url: file.path ?? '',
            size: bytes > 0
                ? '${(bytes / 1024).toStringAsFixed(1)} KB'
                : 'File',
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'File picker is unavailable on this platform. Try text instead.',
        isError: true,
      );
      return;
    }
    if (attachment == null || !mounted) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(conversationControllerProvider(widget.conversationId).notifier)
          .send(
            '',
            attachment: attachment,
            type: attachment.isImage ? MessageType.image : MessageType.file,
          );
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Attachment could not be sent.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showInfo(Conversation? conversation) {
    if (conversation == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                conversation.isGroup
                    ? 'Group conversation • ${conversation.participants.length + 1} members'
                    : conversation.isOnline
                    ? 'Online now'
                    : 'Offline',
                style: TextStyle(fontSize: 11.5, color: context.textSecondary),
              ),
              const Divider(height: 24),
              if (conversation.isGroup) ...[
                const Text(
                  'Participants',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...conversation.participants.map(
                  (employee) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        EmployeeAvatar(
                          name: employee.name,
                          imageUrl: employee.avatarUrl,
                          size: 32,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                employee.designation,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (conversation.peer != null)
                Row(
                  children: [
                    EmployeeAvatar(
                      name: conversation.peer!.name,
                      imageUrl: conversation.peer!.avatarUrl,
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.peer!.designation,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${conversation.peer!.department} • ${conversation.peer!.email}',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    final messagesAsync = ref.watch(
      conversationControllerProvider(widget.conversationId),
    );
    ref.listen(conversationControllerProvider(widget.conversationId), (
      previous,
      next,
    ) {
      if (next.hasValue &&
          next.value!.length != (previous?.value?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (conversation?.isGroup == true)
              EmployeeAvatarGroup(
                names: conversation!.participants
                    .map((employee) => employee.name)
                    .toList(),
                size: 32,
                max: 2,
              )
            else
              EmployeeAvatar(
                name: conversation?.title ?? 'Chat',
                imageUrl: conversation?.peer?.avatarUrl,
                size: 36,
                showStatus: true,
                isOnline: conversation?.isOnline ?? false,
              ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversation?.title ?? 'Conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    conversation?.isGroup == true
                        ? '${conversation!.participants.length + 1} members'
                        : conversation?.isOnline == true
                        ? 'Online'
                        : 'Last seen recently',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      color:
                          conversation?.isOnline == true &&
                              conversation?.isGroup != true
                          ? AppColors.success
                          : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversation info',
            onPressed: () => _showInfo(conversation),
            icon: const Icon(Icons.info_outline_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading messages...'),
              error: (error, _) => AppErrorWidget(
                message: 'Unable to load this conversation.',
                onRetry: () => ref.invalidate(
                  conversationControllerProvider(widget.conversationId),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const AppEmptyState(
                    title: 'No messages yet',
                    message:
                        'Send the first message to start the conversation.',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final previous = index == 0 ? null : messages[index - 1];
                    final showDate =
                        previous == null ||
                        !dates.AppDate.isSameDay(
                          previous.createdAt,
                          message.createdAt,
                        );
                    final showSender =
                        conversation?.isGroup == true &&
                        !message.isMine &&
                        (previous == null ||
                            previous.senderId != message.senderId);
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: message.createdAt),
                        _MessageBubble(
                          message: message,
                          showSender: showSender,
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _messageController,
            sending: _sending,
            onSend: _sendText,
            onAttach: _pickAttachment,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.showSender});

  final ChatMessage message;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showSender)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : context.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(mine ? 14 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 14),
                ),
                border: mine ? null : Border.all(color: context.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachments.isNotEmpty)
                    ...message.attachments.map(
                      (attachment) =>
                          _AttachmentBubble(attachment: attachment, mine: mine),
                    ),
                  if (message.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: message.attachments.isEmpty ? 0 : 7,
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: mine ? Colors.white : context.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dates.AppDate.messageTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 8.5,
                          color: mine
                              ? Colors.white.withValues(alpha: 0.7)
                              : context.textSecondary,
                        ),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == MessageDeliveryStatus.sent
                              ? Icons.check_rounded
                              : message.status == MessageDeliveryStatus.failed
                              ? Icons.error_outline_rounded
                              : Icons.done_all_rounded,
                          size: 12,
                          color: message.status == MessageDeliveryStatus.read
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.65),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentBubble extends StatelessWidget {
  const _AttachmentBubble({required this.attachment, required this.mine});

  final ChatAttachment attachment;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final isRemoteImage =
        attachment.isImage &&
        (attachment.url.startsWith('http://') ||
            attachment.url.startsWith('https://'));
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: mine ? Colors.white.withValues(alpha: 0.12) : context.canvas,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: isRemoteImage
                ? CachedNetworkImage(
                    imageUrl: attachment.url,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _fileIcon(context),
                  )
                : _fileIcon(context),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: mine ? Colors.white : context.textPrimary,
                  ),
                ),
                Text(
                  attachment.size,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.7)
                        : context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileIcon(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: mine
            ? Colors.white.withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        attachment.isImage
            ? Icons.image_outlined
            : Icons.insert_drive_file_outlined,
        size: 20,
        color: mine ? Colors.white : AppColors.primary,
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = dates.AppDate.isSameDay(date, now)
        ? 'Today'
        : dates.AppDate.isSameDay(date, now.subtract(const Duration(days: 1)))
        ? 'Yesterday'
        : dates.AppDate.shortDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.line)),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Attach file',
                onPressed: sending ? null : onAttach,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 23),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 13, color: context.textPrimary),
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 42,
                height: 42,
                child: FilledButton(
                  onPressed: sending ? null : onSend,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(42, 42),
                    shape: const CircleBorder(),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

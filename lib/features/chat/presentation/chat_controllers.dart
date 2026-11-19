import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../domain/chat.dart';

class ConversationsController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() {
    return ref.watch(chatRepositoryProvider).fetchConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Conversation>>();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).fetchConversations(),
    );
  }

  Future<void> markRead(String conversationId) async {
    await ref.read(chatRepositoryProvider).markRead(conversationId);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(unreadCount: 0)
                : conversation,
          )
          .toList(),
    );
  }
}

class ConversationController extends AsyncNotifier<List<ChatMessage>> {
  ConversationController(this.conversationId);

  final String conversationId;
  bool _sending = false;

  bool get isSending => _sending;

  @override
  Future<List<ChatMessage>> build() {
    return ref.watch(chatRepositoryProvider).fetchMessages(conversationId);
  }

  Future<void> send(
    String text, {
    ChatAttachment? attachment,
    MessageType type = MessageType.text,
  }) async {
    if (_sending) return;
    _sending = true;
    try {
      final message = await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId,
            text: text,
            attachment: attachment,
            type: type,
          );
      final current = state.value ?? const <ChatMessage>[];
      state = AsyncData([...current, message]);
      await ref
          .read(conversationsControllerProvider.notifier)
          .markRead(conversationId);
    } finally {
      _sending = false;
    }
  }
}

final conversationsControllerProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
      ConversationsController.new,
    );

final conversationControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ConversationController, List<ChatMessage>, String>(
      ConversationController.new,
    );

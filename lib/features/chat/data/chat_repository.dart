import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/chat.dart';

abstract class ChatRepository {
  Future<List<Conversation>> fetchConversations();
  Future<List<ChatMessage>> fetchMessages(String conversationId);
  Future<ChatMessage> sendMessage(
    String conversationId, {
    required String text,
    ChatAttachment? attachment,
    MessageType type = MessageType.text,
  });
  Future<void> markRead(String conversationId);
}

class MockChatRepository implements ChatRepository {
  MockChatRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Conversation>> fetchConversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_db.conversations);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List.unmodifiable(_db.messages[conversationId] ?? const []);
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId, {
    required String text,
    ChatAttachment? attachment,
    MessageType type = MessageType.text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final message = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: _db.currentUser.id,
      senderName: _db.currentUser.name,
      text: text,
      createdAt: DateTime.now(),
      isMine: true,
      status: MessageDeliveryStatus.sent,
      type: attachment == null
          ? type
          : (attachment.isImage ? MessageType.image : MessageType.file),
      attachments: attachment == null ? const [] : [attachment],
    );
    _db.messages.putIfAbsent(conversationId, () => []);
    _db.messages[conversationId]!.add(message);

    final index = _db.conversations.indexWhere(
      (item) => item.id == conversationId,
    );
    if (index != -1) {
      _db.conversations[index] = _db.conversations[index].copyWith(
        lastMessage: text.isEmpty
            ? '${attachment?.isImage == true ? 'Photo' : 'File'}: ${attachment?.name ?? ''}'
            : text,
        lastMessageAt: message.createdAt,
      );
    }
    return message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final index = _db.conversations.indexWhere(
      (item) => item.id == conversationId,
    );
    if (index != -1) {
      _db.conversations[index] = _db.conversations[index].copyWith(
        unreadCount: 0,
      );
    }
  }
}

class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Conversation>> fetchConversations() async {
    final data = await _client.get(ApiEndpoints.conversations);
    return asList(
      data,
    ).map((item) => Conversation.fromJson(mapOf(item))).toList();
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final data = await _client.get(ApiEndpoints.messages(conversationId));
    return asList(
      data,
    ).map((item) => ChatMessage.fromJson(mapOf(item), meId: 'me')).toList();
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId, {
    required String text,
    ChatAttachment? attachment,
    MessageType type = MessageType.text,
  }) async {
    final data = await _client.post(
      ApiEndpoints.messages(conversationId),
      data: {
        'message': text,
        'type': attachment == null
            ? type.name
            : (attachment.isImage ? 'image' : 'file'),
        if (attachment != null)
          'attachment': {
            'name': attachment.name,
            'url': attachment.url,
            'size': attachment.size,
            'is_image': attachment.isImage,
          },
      },
    );
    return ChatMessage.fromJson(asMap(data), meId: 'me');
  }

  @override
  Future<void> markRead(String conversationId) async {
    await _client.patch('${ApiEndpoints.conversation(conversationId)}/read');
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockChatRepository(MockDatabase.instance);
  }
  return ApiChatRepository(ref.watch(apiClientProvider));
});

import '../../profile/domain/employee.dart';

enum MessageDeliveryStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, file, system }

class ChatAttachment {
  const ChatAttachment({
    required this.name,
    required this.url,
    this.size = '',
    this.isImage = false,
  });

  final String name;
  final String url;
  final String size;
  final bool isImage;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.status = MessageDeliveryStatus.read,
    this.type = MessageType.text,
    this.attachments = const [],
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final MessageDeliveryStatus status;
  final MessageType type;
  final List<ChatAttachment> attachments;

  ChatMessage copyWith({MessageDeliveryStatus? status}) => ChatMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    text: text,
    createdAt: createdAt,
    isMine: isMine,
    status: status ?? this.status,
    type: type,
    attachments: attachments,
  );

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String meId,
  }) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderName: (json['sender_name'] ?? '').toString(),
      text: (json['text'] ?? json['message'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isMine: (json['sender_id'] ?? '').toString() == meId,
      status: MessageDeliveryStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageDeliveryStatus.delivered,
      ),
      type: MessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    this.isGroup = false,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.pinned = false,
  });

  final String id;
  final String title;
  final List<Employee> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool isGroup;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool pinned;

  Employee? get peer => participants.isEmpty ? null : participants.first;

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isTyping,
  }) => Conversation(
    id: id,
    title: title,
    participants: participants,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    isGroup: isGroup,
    unreadCount: unreadCount ?? this.unreadCount,
    isOnline: isOnline,
    isTyping: isTyping ?? this.isTyping,
    pinned: pinned,
  );

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? 'Conversation').toString(),
    participants:
        (json['participants'] as List?)
            ?.map(
              (item) =>
                  Employee.fromJson((item as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    lastMessage: (json['last_message'] ?? '').toString(),
    lastMessageAt:
        DateTime.tryParse(json['last_message_at']?.toString() ?? '') ??
        DateTime.now(),
    isGroup: json['is_group'] == true,
    unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    isOnline: json['is_online'] == true,
    pinned: json['pinned'] == true,
  );
}

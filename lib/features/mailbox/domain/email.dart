enum MailFolder { inbox, sent, drafts }

class EmailAttachment {
  const EmailAttachment({
    required this.name,
    required this.sizeLabel,
    this.url,
  });

  final String name;
  final String sizeLabel;
  final String? url;
}

class EmailMessage {
  const EmailMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.sentAt,
    required this.folder,
    this.isRead = false,
    this.attachments = const [],
  });

  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime sentAt;
  final MailFolder folder;
  final bool isRead;
  final List<EmailAttachment> attachments;

  String get preview {
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 80) return clean;
    return '${clean.substring(0, 80)}...';
  }

  EmailMessage copyWith({bool? isRead}) => EmailMessage(
    id: id,
    from: from,
    to: to,
    subject: subject,
    body: body,
    sentAt: sentAt,
    folder: folder,
    isRead: isRead ?? this.isRead,
    attachments: attachments,
  );

  factory EmailMessage.fromJson(Map<String, dynamic> json) => EmailMessage(
    id: (json['id'] ?? '').toString(),
    from: (json['from'] ?? '').toString(),
    to: (json['to'] ?? '').toString(),
    subject: (json['subject'] ?? '(No subject)').toString(),
    body: (json['body'] ?? '').toString(),
    sentAt:
        DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
    folder: MailFolder.values.firstWhere(
      (folder) => folder.name == json['folder'],
      orElse: () => MailFolder.inbox,
    ),
    isRead: json['is_read'] == true,
    attachments:
        (json['attachments'] as List?)
            ?.map(
              (item) => EmailAttachment(
                name: (item['name'] ?? 'Attachment').toString(),
                sizeLabel: (item['size'] ?? '').toString(),
                url: item['url']?.toString(),
              ),
            )
            .toList() ??
        const [],
  );
}

class MailSendResult {
  const MailSendResult({required this.message, required this.delivered});
  final EmailMessage message;
  final bool delivered;
}

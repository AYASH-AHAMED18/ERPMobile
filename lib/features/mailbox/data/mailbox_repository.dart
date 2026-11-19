import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/email.dart';

abstract class MailboxRepository {
  Future<List<EmailMessage>> fetchEmails(MailFolder folder);
  Future<void> markRead(String id);
  Future<MailSendResult> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? attachmentName,
  });

  Future<EmailMessage> saveDraft({
    required String to,
    required String subject,
    required String body,
    String? attachmentName,
  });
}

class MockMailboxRepository implements MailboxRepository {
  MockMailboxRepository(this._db);
  final MockDatabase _db;

  @override
  Future<List<EmailMessage>> fetchEmails(MailFolder folder) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _db.emails.where((email) => email.folder == folder).toList();
  }

  @override
  Future<void> markRead(String id) async {
    final index = _db.emails.indexWhere((email) => email.id == id);
    if (index != -1) {
      _db.emails[index] = _db.emails[index].copyWith(isRead: true);
    }
  }

  @override
  Future<MailSendResult> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? attachmentName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final message = EmailMessage(
      id: 'mail-${DateTime.now().millisecondsSinceEpoch}',
      from: _db.currentUser.email,
      to: to,
      subject: subject,
      body: body,
      sentAt: DateTime.now(),
      folder: MailFolder.sent,
      isRead: true,
      attachments: attachmentName == null
          ? const []
          : [EmailAttachment(name: attachmentName, sizeLabel: 'Attached')],
    );
    _db.emails.add(message);
    return MailSendResult(message: message, delivered: false);
  }

  @override
  Future<EmailMessage> saveDraft({
    required String to,
    required String subject,
    required String body,
    String? attachmentName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final draft = EmailMessage(
      id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
      from: _db.currentUser.email,
      to: to,
      subject: subject.isEmpty ? '(No subject)' : subject,
      body: body,
      sentAt: DateTime.now(),
      folder: MailFolder.drafts,
      attachments: attachmentName == null
          ? const []
          : [EmailAttachment(name: attachmentName, sizeLabel: 'Attached')],
    );
    _db.emails.add(draft);
    return draft;
  }
}

class ApiMailboxRepository implements MailboxRepository {
  ApiMailboxRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<EmailMessage>> fetchEmails(MailFolder folder) async {
    final data = await _client.get(
      ApiEndpoints.mailbox,
      query: {'folder': folder.name},
    );
    return asList(
      data,
    ).map((item) => EmailMessage.fromJson(mapOf(item))).toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _client.patch('${ApiEndpoints.email(id)}/read');
  }

  @override
  Future<MailSendResult> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? attachmentName,
  }) async {
    final data = await _client.post(
      ApiEndpoints.sendMail,
      data: {
        'to': to,
        'subject': subject,
        'body': body,
        'attachment_name': ?attachmentName,
      },
    );
    return MailSendResult(
      message: EmailMessage.fromJson(asMap(data)),
      delivered: true,
    );
  }

  @override
  Future<EmailMessage> saveDraft({
    required String to,
    required String subject,
    required String body,
    String? attachmentName,
  }) async {
    final data = await _client.post(
      '${ApiEndpoints.mailbox}/drafts',
      data: {
        'to': to,
        'subject': subject,
        'body': body,
        'attachment_name': ?attachmentName,
      },
    );
    return EmailMessage.fromJson(asMap(data));
  }
}

final mailboxRepositoryProvider = Provider<MailboxRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockMailboxRepository(MockDatabase.instance);
  }
  return ApiMailboxRepository(ref.watch(apiClientProvider));
});

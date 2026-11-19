import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mailbox_repository.dart';
import '../domain/email.dart';

class MailboxController extends AsyncNotifier<List<EmailMessage>> {
  MailboxController(this.folder);

  final MailFolder folder;

  @override
  Future<List<EmailMessage>> build() {
    return ref.watch(mailboxRepositoryProvider).fetchEmails(folder);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<EmailMessage>>();
    state = await AsyncValue.guard(
      () => ref.read(mailboxRepositoryProvider).fetchEmails(folder),
    );
  }

  Future<void> markRead(String id) async {
    await ref.read(mailboxRepositoryProvider).markRead(id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current
          .map((email) => email.id == id ? email.copyWith(isRead: true) : email)
          .toList(),
    );
  }
}

final mailboxControllerProvider =
    AsyncNotifierProvider.family<
      MailboxController,
      List<EmailMessage>,
      MailFolder
    >(MailboxController.new);

final selectedMailFolderProvider =
    NotifierProvider<MailFolderController, MailFolder>(
      MailFolderController.new,
    );

class MailFolderController extends Notifier<MailFolder> {
  @override
  MailFolder build() => MailFolder.inbox;
  void select(MailFolder folder) => state = folder;
}

final composeResultProvider = FutureProvider.autoDispose<MailSendResult?>(
  (ref) async => null,
);

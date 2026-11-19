import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/mailbox_repository.dart';
import '../domain/email.dart';
import 'mailbox_controllers.dart';

class MailboxScreen extends ConsumerStatefulWidget {
  const MailboxScreen({super.key});

  @override
  ConsumerState<MailboxScreen> createState() => _MailboxScreenState();
}

class _MailboxScreenState extends ConsumerState<MailboxScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EmailMessage> _filtered(List<EmailMessage> emails) {
    if (_search.trim().isEmpty) return emails;
    final query = _search.toLowerCase();
    return emails
        .where(
          (email) =>
              email.subject.toLowerCase().contains(query) ||
              email.from.toLowerCase().contains(query) ||
              email.to.toLowerCase().contains(query) ||
              email.preview.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(selectedMailFolderProvider);
    final emailsAsync = ref.watch(mailboxControllerProvider(folder));
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mailbox'),
            Text(
              'Company email and messages',
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
            tooltip: 'Compose email',
            onPressed: () => context.push('/mailbox/compose'),
            icon: const Icon(Icons.edit_outlined, size: 21),
          ),
          IconButton(
            tooltip: 'Refresh mailbox',
            onPressed: () =>
                ref.read(mailboxControllerProvider(folder).notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/mailbox/compose'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded, size: 19),
        label: const Text(
          'Compose',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Column(
              children: [
                _FolderTabs(
                  selected: folder,
                  onSelected: (value) {
                    ref.read(selectedMailFolderProvider.notifier).select(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                AppSearchField(
                  controller: _searchController,
                  hint: 'Search mail',
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Expanded(
            child: emailsAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading mail...'),
              error: (error, _) => AppErrorWidget(
                message: 'Unable to load this mailbox folder.',
                onRetry: () => ref
                    .read(mailboxControllerProvider(folder).notifier)
                    .refresh(),
              ),
              data: (emails) {
                final filtered = _filtered(emails);
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: _search.isNotEmpty
                        ? 'No matching emails'
                        : folder == MailFolder.inbox
                        ? 'Your inbox is empty'
                        : folder == MailFolder.sent
                        ? 'No sent messages'
                        : 'No drafts saved',
                    message: _search.isNotEmpty
                        ? 'Try another search term.'
                        : folder == MailFolder.drafts
                        ? 'Emails you save as drafts will appear here.'
                        : 'Messages will appear here when available.',
                    icon: folder == MailFolder.drafts
                        ? Icons.drafts_outlined
                        : Icons.mail_outline_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(mailboxControllerProvider(folder).notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final email = filtered[index];
                      return _EmailCard(
                        email: email,
                        folder: folder,
                        onTap: () =>
                            context.push('/mailbox/${email.id}', extra: email),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderTabs extends StatelessWidget {
  const _FolderTabs({required this.selected, required this.onSelected});

  final MailFolder selected;
  final ValueChanged<MailFolder> onSelected;

  @override
  Widget build(BuildContext context) {
    final folders = [
      (MailFolder.inbox, 'Inbox', Icons.inbox_outlined, AppColors.primary),
      (MailFolder.sent, 'Sent', Icons.send_outlined, AppColors.info),
      (MailFolder.drafts, 'Drafts', Icons.drafts_outlined, AppColors.warning),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: folders.map((folder) {
          final active = selected == folder.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(folder.$1),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? folder.$4.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      folder.$3,
                      size: 15,
                      color: active ? folder.$4 : context.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      folder.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? folder.$4 : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  const _EmailCard({
    required this.email,
    required this.folder,
    required this.onTap,
  });

  final EmailMessage email;
  final MailFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread =
        !email.isRead &&
        (folder == MailFolder.inbox || folder == MailFolder.drafts);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.025)
                : context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : context.line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: unread
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : context.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: unread
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : context.line,
                  ),
                ),
                child: Icon(
                  folder == MailFolder.sent
                      ? Icons.outgoing_mail
                      : folder == MailFolder.drafts
                      ? Icons.drafts_outlined
                      : Icons.mail_outline_rounded,
                  size: 17,
                  color: unread ? AppColors.primary : context.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            folder == MailFolder.sent
                                ? 'To: ${email.to}'
                                : email.from,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dates.AppDate.isSameDay(email.sentAt, DateTime.now())
                              ? dates.AppDate.messageTime(email.sentAt)
                              : dates.AppDate.relativeDate(email.sentAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: unread
                                ? AppColors.primary
                                : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (unread) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            email.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        if (email.attachments.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.attach_file_rounded,
                            size: 12,
                            color: context.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.35,
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
    );
  }
}

class EmailDetailScreen extends ConsumerStatefulWidget {
  const EmailDetailScreen({super.key, required this.email});

  final EmailMessage email;

  @override
  ConsumerState<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends ConsumerState<EmailDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref
          .read(mailboxControllerProvider(widget.email.folder).notifier)
          .markRead(widget.email.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: const Text('Email'),
        actions: [
          IconButton(
            tooltip: 'Reply',
            onPressed: () => context.push('/mailbox/compose', extra: email),
            icon: const Icon(Icons.reply_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: email.folder.name.toUpperCase(),
                      color: email.folder == MailFolder.inbox
                          ? AppColors.primary
                          : AppColors.info,
                      compact: true,
                    ),
                    const Spacer(),
                    Text(
                      dates.AppDate.full(email.sentAt),
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  email.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          email.from.isEmpty
                              ? '?'
                              : email.from.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.from,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'To: ${email.to}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  email.body,
                  style: const TextStyle(fontSize: 13, height: 1.65),
                ),
                if (email.attachments.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Attachments (${email.attachments.length})',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...email.attachments.map(
                    (attachment) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.canvas,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: context.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              attachment.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            attachment.sizeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: 'Reply',
            icon: Icons.reply_rounded,
            tonal: true,
            onPressed: () => context.push('/mailbox/compose', extra: email),
          ),
        ],
      ),
    );
  }
}

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, this.replyTo});

  final EmailMessage? replyTo;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  String? _attachmentName;
  bool _sending = false;
  bool _savingDraft = false;

  @override
  void initState() {
    super.initState();
    final reply = widget.replyTo;
    _toController = TextEditingController(text: reply?.from ?? '');
    _subjectController = TextEditingController(
      text: reply == null ? '' : 'Re: ${reply.subject}',
    );
    _bodyController = TextEditingController(
      text: reply == null
          ? ''
          : '\n\n---\nOn ${dates.AppDate.shortDate(reply.sentAt)}, ${reply.from} wrote:\n${reply.body}',
    );
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final files = await FilePicker.pickFiles();
      final file = files.isEmpty ? null : files.first;
      if (file != null) setState(() => _attachmentName = file.name);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'File picker is unavailable on this platform.',
        isError: true,
      );
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(mailboxRepositoryProvider)
          .sendEmail(
            to: _toController.text.trim(),
            subject: _subjectController.text.trim(),
            body: _bodyController.text.trim(),
            attachmentName: _attachmentName,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      ref.invalidate(mailboxControllerProvider(MailFolder.sent));
      Navigator.pop(context);
      showAppSnackBarWith(
        messenger,
        result.delivered
            ? 'Message sent successfully.'
            : 'Saved to the demo outbox. Email delivery is not connected.',
        isSuccess: result.delivered,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Message could not be sent.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_toController.text.trim().isEmpty &&
        _subjectController.text.trim().isEmpty &&
        _bodyController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Nothing to save as a draft.', isError: true);
      return;
    }
    setState(() => _savingDraft = true);
    try {
      await ref
          .read(mailboxRepositoryProvider)
          .saveDraft(
            to: _toController.text.trim(),
            subject: _subjectController.text.trim(),
            body: _bodyController.text.trim(),
            attachmentName: _attachmentName,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      ref.invalidate(mailboxControllerProvider(MailFolder.drafts));
      Navigator.pop(context);
      showAppSnackBarWith(messenger, 'Draft saved.', isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Draft could not be saved.', isError: true);
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _sending || _savingDraft;
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Text(widget.replyTo == null ? 'Compose email' : 'Reply'),
        actions: [
          TextButton(
            onPressed: busy ? null : _saveDraft,
            child: const Text('Save draft', style: TextStyle(fontSize: 11.5)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  AppTextField(
                    controller: _toController,
                    label: 'To',
                    hint: 'recipient@speedcodelabs.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Recipient is required';
                      final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                      if (!emailRegex.hasMatch(text)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _subjectController,
                    label: 'Subject',
                    hint: 'Email subject',
                    prefixIcon: Icons.subject_rounded,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Subject is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _bodyController,
                    label: 'Message',
                    hint: 'Write your message...',
                    maxLines: 12,
                    minLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Message body is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: busy ? null : _pickAttachment,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.line),
                        color: context.canvas,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attachmentName ?? 'Attach a file (optional)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _attachmentName == null
                                    ? context.textSecondary
                                    : context.textPrimary,
                              ),
                            ),
                          ),
                          if (_attachmentName != null)
                            IconButton(
                              tooltip: 'Remove attachment',
                              onPressed: () =>
                                  setState(() => _attachmentName = null),
                              icon: const Icon(Icons.close_rounded, size: 17),
                            )
                          else
                            Icon(
                              Icons.upload_file_rounded,
                              size: 18,
                              color: context.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (AppConfig.useMockData)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Demo mode: outgoing mail is saved locally and is not delivered. '
                        'Connect the backend mail service to send real email.',
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.45,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            AppPrimaryButton(
              label: 'Send email',
              icon: Icons.send_rounded,
              loading: _sending,
              onPressed: busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

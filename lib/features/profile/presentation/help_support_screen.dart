import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_states.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I apply for leave?',
      'Open Leave from the bottom navigation, complete the application card and submit. HR will review the request and update its status.',
    ),
    (
      'Why can I not edit my department?',
      'Department, designation and email are HR-managed fields. Contact HR if any of these details need to be corrected.',
    ),
    (
      'How do project progress percentages work?',
      'Project progress is derived from the tasks currently linked to that project. Task-level progress is used when available, otherwise status is used as an estimate.',
    ),
    (
      'How do I join a company event?',
      'Open Events, choose an event and review the registration note. Registration is managed by the event organizer or HR until an events registration API is connected.',
    ),
    (
      'Why is a calendar event not appearing?',
      'Pull down to refresh the calendar. Project deadlines and approved leave are combined from the task board and leave service.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ErpModuleScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppPageTitle(
            title: 'Help & Support',
            subtitle: 'Answers and ways to reach the team',
            onBack: () => context.pop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SupportHero(),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ModuleSectionTitle(
              title: 'Frequently asked questions',
              subtitle: 'Common ERP and account questions',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _faqs.length; i++) ...[
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      iconColor: AppColors.primary,
                      collapsedIconColor: context.textSecondary,
                      title: Text(
                        _faqs[i].$1,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _faqs[i].$2,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.5,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i != _faqs.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ModuleSectionTitle(
              title: 'Contact support',
              subtitle: 'Reach People Operations or IT',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    title: 'Email support',
                    subtitle: 'support@speedcodelabs.com',
                    onTap: () => _open(
                      context,
                      Uri(
                        scheme: 'mailto',
                        path: 'support@speedcodelabs.com',
                        query: 'subject=SpeedCode ERP support',
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 48),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    title: 'Call People Operations',
                    subtitle: '+94 11 234 5678',
                    onTap: () => _open(
                      context,
                      Uri(scheme: 'tel', path: '+94112345678'),
                    ),
                  ),
                  const Divider(height: 1, indent: 48),
                  _ContactRow(
                    icon: Icons.schedule_rounded,
                    title: 'Support hours',
                    subtitle: 'Weekdays, 9:00 AM - 5:30 PM',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'For urgent attendance or payroll issues, contact your department lead and People Operations directly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.45,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        'This contact option is unavailable on this device.',
        isError: true,
      );
    }
  }
}

class _SupportHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 25,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We are here to help',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Browse the FAQs or contact the support team for ERP access, leave and project questions.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, size: 18, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 9.5, color: context.textSecondary),
      ),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: context.textSecondary,
            ),
    );
  }
}

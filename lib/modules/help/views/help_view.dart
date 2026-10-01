import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/help_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/help_controller.dart';

/// Pusat Bantuan: kontak (tel/wa/email/web) + FAQ accordion (FR-03.2, publik).
class HelpView extends GetView<HelpController> {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.data.value == null) {
            return const LoadingState(message: 'Memuat pusat bantuan...');
          }
          if (controller.data.value == null) {
            final error = controller.errorMessage.value;
            if (error != null) {
              return ErrorState(message: error, onRetry: controller.fetch);
            }
            return const EmptyState(
              icon: Icons.support_agent_outlined,
              title: 'Pusat bantuan belum tersedia',
              subtitle: 'Tarik ke bawah untuk memuat ulang.',
            );
          }
          if (controller.contacts.isEmpty && controller.faqs.isEmpty) {
            return const EmptyState(
              icon: Icons.support_agent_outlined,
              title: 'Belum ada konten bantuan',
              subtitle: 'Kontak dan pertanyaan umum akan tampil di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: controller.fetch,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (controller.contacts.isNotEmpty) ...[
                  const SectionHeader(title: 'Hubungi Kami'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < controller.contacts.length;
                            i++) ...[
                          _contactRow(controller.contacts[i]),
                          if (i < controller.contacts.length - 1)
                            const Divider(indent: 70, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
                ],
                if (controller.faqs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Pertanyaan Umum'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: Column(
                        children: [
                          for (var i = 0; i < controller.faqs.length; i++)
                            _faqTile(controller.faqs[i],
                                showDivider: i < controller.faqs.length - 1),                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Belum menemukan jawaban? Hubungi kami lewat kontak di atas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _contactRow(HelpContact contact) {
    final icon = _iconFor(contact.type);
    final color = _colorFor(contact.type);
    return InkWell(
      onTap: () => controller.openContact(contact),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.title ?? 'Kontak',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.value ?? '',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 17, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(Faq faq, {required bool showDivider}) {
    return Column(
      children: [
        ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textLight,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              faq.question ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  faq.answer ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        if (showDivider) const Divider(indent: 16, endIndent: 16),
      ],
    );
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'phone':
      case 'tel':
        return Icons.phone_outlined;
      case 'wa':
      case 'whatsapp':
        return Icons.chat_outlined;
      case 'email':
        return Icons.mail_outline;
      default:
        return Icons.language_outlined;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'phone':
      case 'tel':
        return AppColors.secondary;
      case 'wa':
      case 'whatsapp':
        return AppColors.primary;
      case 'email':
        return AppColors.accent;
      default:
        return AppColors.primaryDark;
    }
  }
}

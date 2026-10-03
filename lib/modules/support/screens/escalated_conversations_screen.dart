import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/bot_conversation.dart';
import '../providers/bot_provider.dart';

class EscalatedConversationsScreen extends StatefulWidget {
  const EscalatedConversationsScreen({super.key});

  @override
  State<EscalatedConversationsScreen> createState() =>
      _EscalatedConversationsScreenState();
}

class _EscalatedConversationsScreenState
    extends State<EscalatedConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BotProvider>().loadEscalatedConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BotProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: PharmaConnectColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Conversations escaladées',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Text(
                        provider.error!,
                        style: PharmaConnectTypography.body2.copyWith(
                          color: PharmaConnectColors.accentRed,
                        ),
                      ),
                    )
                  : provider.escalatedConversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.support_agent,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune escalade en attente',
                            style: PharmaConnectTypography.heading3,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.escalatedConversations.length,
                      itemBuilder: (context, index) {
                        final conv = provider.escalatedConversations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildConversationTile(conv),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BotConversation conv) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/support/staff/conversations/${conv.id}'),
      child: Row(
        children: [
          const Icon(
            Icons.person_pin_circle_outlined,
            color: PharmaConnectColors.accentOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.escalationReason ?? 'Demande d\'escalade',
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mis à jour le ${_formatDate(conv.updatedAt)}',
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

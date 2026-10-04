import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/bot_conversation.dart';
import '../providers/bot_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conversations escaladées',
                      style: context.text.heading2,
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
                        style: context.text.body2.copyWith(
                          color: context.palette.danger,
                        ),
                      ),
                    )
                  : provider.escalatedConversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune escalade en attente',
                            style: context.text.heading3,
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
          Icon(
            Icons.person_pin_circle_outlined,
            color: context.palette.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.escalationReason ?? 'Demande d\'escalade',
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mis à jour le ${_formatDate(conv.updatedAt)}',
                  style: context.text.micro,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

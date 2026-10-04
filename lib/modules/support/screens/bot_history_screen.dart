import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/bot_conversation.dart';
import '../providers/bot_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class BotHistoryScreen extends StatefulWidget {
  const BotHistoryScreen({super.key});

  @override
  State<BotHistoryScreen> createState() => _BotHistoryScreenState();
}

class _BotHistoryScreenState extends State<BotHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<BotProvider>().loadHistory(userId);
      }
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
                      'Historique des conversations',
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
                  : provider.history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune conversation',
                            style: context.text.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vos échanges avec l\'assistant apparaîtront ici',
                            style: context.text.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.history.length,
                      itemBuilder: (context, index) {
                        final conv = provider.history[index];
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
    final lastMessage = conv.messages.isNotEmpty ? conv.messages.last : null;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/support/chat'),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(conv.status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _statusLabel(conv.status),
                      style: context.text.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _statusColor(conv.status),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(conv.updatedAt),
                      style: context.text.micro,
                    ),
                  ],
                ),
                if (lastMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.text,
                    style: context.text.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'escalated':
        return context.palette.warning;
      case 'resolved':
        return context.palette.success;
      case 'abandoned':
        return context.palette.textSecondary;
      default:
        return context.palette.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'escalated':
        return 'Escaladée';
      case 'resolved':
        return 'Résolue';
      case 'abandoned':
        return 'Abandonnée';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

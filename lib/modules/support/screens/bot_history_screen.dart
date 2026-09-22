import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/bot_conversation.dart';
import '../providers/bot_provider.dart';

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
            Row(
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
                    'Historique des conversations',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
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
                          const Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune conversation',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vos échanges avec l\'assistant apparaîtront ici',
                            style: PharmaConnectTypography.body2,
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
                      style: PharmaConnectTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _statusColor(conv.status),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(conv.updatedAt),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
                if (lastMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.text,
                    style: PharmaConnectTypography.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'escalated':
        return PharmaConnectColors.accentOrange;
      case 'resolved':
        return PharmaConnectColors.accentGreen;
      case 'abandoned':
        return PharmaConnectColors.textSecondary;
      default:
        return PharmaConnectColors.accentCyan;
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

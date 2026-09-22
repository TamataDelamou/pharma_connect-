import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/bot_conversation.dart';
import '../providers/bot_provider.dart';

class StaffConversationScreen extends StatefulWidget {
  final String conversationId;

  const StaffConversationScreen({super.key, required this.conversationId});

  @override
  State<StaffConversationScreen> createState() =>
      _StaffConversationScreenState();
}

class _StaffConversationScreenState extends State<StaffConversationScreen> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BotProvider>().loadConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BotProvider>();
    final conversation = provider.currentConversation;

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
                    'Conversation escaladée',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading && conversation == null
                  ? const Center(child: CircularProgressIndicator())
                  : conversation == null
                  ? Center(
                      child: Text(
                        provider.error ?? 'Conversation introuvable',
                        style: PharmaConnectTypography.body2.copyWith(
                          color: PharmaConnectColors.accentRed,
                        ),
                      ),
                    )
                  : _buildMessages(conversation),
            ),
            const SizedBox(height: 12),
            if (conversation?.status == 'escalated') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: 'Répondre au patient...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: PharmaConnectColors.accentCyan,
                    ),
                    onPressed: () => _reply(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Clôturer l\'escalade',
                icon: Icons.check_circle_outline,
                onPressed: () => _resolve(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(BotConversation conversation) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: conversation.messages.length,
        itemBuilder: (context, index) {
          final msg = conversation.messages[index];
          final isStaff = msg.sender == 'staff';
          final isUser = msg.sender == 'user';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: isUser
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: isStaff
                      ? PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.15,
                        )
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isStaff
                        ? PharmaConnectColors.accentOrange.withValues(
                            alpha: 0.2,
                          )
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStaff ? 'Agent' : (isUser ? 'Patient' : 'Assistant'),
                      style: PharmaConnectTypography.micro.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(msg.text, style: PharmaConnectTypography.body2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _reply(BuildContext context) async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;
    final provider = context.read<BotProvider>();
    _replyController.clear();
    await provider.replyAsStaff(widget.conversationId, message);
  }

  Future<void> _resolve(BuildContext context) async {
    final provider = context.read<BotProvider>();
    final success = await provider.resolveEscalatedConversation(
      widget.conversationId,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalade clôturée'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
      context.pop();
    }
  }
}

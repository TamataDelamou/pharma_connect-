import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/bot_conversation.dart';
import '../providers/bot_provider.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<BotProvider>().startConversation(userId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BotProvider>();
    final conversation = provider.currentConversation;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬 Assistant PharmaConnect',
                        style: PharmaConnectTypography.heading2,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Je suis là pour vous aider 24h/24',
                        style: PharmaConnectTypography.micro,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 8),
                if (conversation?.status == 'escalated')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentOrange.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Text(
                      '👨‍💼 Agent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PharmaConnectColors.accentOrange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: PharmaConnectColors.accentRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              final userId = SupabaseService().currentUser?.id;
                              if (userId != null) {
                                provider.startConversation(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : conversation == null
                  ? const SizedBox.shrink()
                  : _buildMessages(conversation, provider),
            ),

            // Input
            if (conversation?.status != 'escalated' &&
                conversation?.status != 'resolved')
              _buildInput(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(BotConversation conversation, BotProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: conversation.messages.length + (provider.isThinking ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= conversation.messages.length) {
            return _buildTypingIndicator();
          }
          final msg = conversation.messages[index];
          final isUser = msg.sender == 'user';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isUser
                        ? const Radius.circular(12)
                        : const Radius.circular(4),
                    bottomRight: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(12),
                  ),
                  border: Border.all(
                    color: isUser
                        ? PharmaConnectColors.accentCyan.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: isUser
                          ? PharmaConnectTypography.body1
                          : PharmaConnectTypography.body2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(1),
              const SizedBox(width: 4),
              _buildDot(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: PharmaConnectColors.textSecondary,
      ),
    );
  }

  Widget _buildInput(BotProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Écrivez votre message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Colors.white10,
              ),
              onSubmitted: (_) => _sendMessage(provider),
              enabled: !provider.isThinking,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: provider.isThinking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        PharmaConnectColors.accentCyan,
                      ),
                    ),
                  )
                : const Icon(Icons.send, color: PharmaConnectColors.accentCyan),
            onPressed: provider.isThinking
                ? null
                : () => _sendMessage(provider),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: PharmaConnectColors.textSecondary,
            ),
            onPressed: () => _showMenu(provider),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BotProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    provider.sendMessage(text);
    _scrollToBottom();
  }

  void _showMenu(BotProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PharmaConnectColors.primaryDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.person_add,
                color: PharmaConnectColors.accentCyan,
              ),
              title: const Text('Parler à un agent'),
              subtitle: const Text('Un humain prendra le relais'),
              onTap: () {
                Navigator.pop(ctx);
                _showEscalateDialog(provider);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.history,
                color: PharmaConnectColors.textSecondary,
              ),
              title: const Text('Voir mon historique'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/support/bot/history');
              },
            ),
            if (provider.currentConversation?.status == 'resolved')
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: PharmaConnectColors.accentRed,
                ),
                title: const Text('Effacer la conversation'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.clearConversation();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEscalateDialog(BotProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Parler à un agent'),
        content: const Text(
          'Un agent humain va prendre le relais de la conversation. '
          'Un temps d\'attente peut être nécessaire.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.escalate();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demande d\'escalade envoyée'),
                  backgroundColor: PharmaConnectColors.accentGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

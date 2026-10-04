import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../services/messaging_service.dart';
import '../models/async_message.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class AsyncMessagingScreen extends StatefulWidget {
  final String patientId;
  final String professionalId;
  final String? consultationId;

  const AsyncMessagingScreen({
    super.key,
    required this.patientId,
    required this.professionalId,
    this.consultationId,
  });

  @override
  State<AsyncMessagingScreen> createState() => _AsyncMessagingScreenState();
}

class _AsyncMessagingScreenState extends State<AsyncMessagingScreen> {
  final MessagingService _service = MessagingService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<AsyncMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      _messages = await _service.getMessages(
        patientId: widget.patientId,
        professionalId: widget.professionalId,
        consultationId: widget.consultationId,
      );
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() => _isSending = true);

    try {
      final msg = await _service.sendMessage(
        patientId: widget.patientId,
        professionalId: widget.professionalId,
        message: text,
        consultationId: widget.consultationId,
      );
      setState(() {
        _messages.add(msg);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseService().currentUser?.id;

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
                      '💬 Messages',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: context.palette.textSecondary,
                  ),
                  onPressed: _loadMessages,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMessages,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isMine = msg.senderId == userId;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Align(
                                    alignment: isMine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMine
                                            ? context.palette.primary
                                                  .withValues(alpha: 0.15)
                                            : context.palette.surfaceMuted,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(12),
                                          topRight: const Radius.circular(12),
                                          bottomLeft: isMine
                                              ? const Radius.circular(12)
                                              : const Radius.circular(4),
                                          bottomRight: isMine
                                              ? const Radius.circular(4)
                                              : const Radius.circular(12),
                                        ),
                                        border: Border.all(
                                          color: isMine
                                              ? context.palette.primary
                                                    .withValues(alpha: 0.2)
                                              : context.palette.surface,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.message,
                                            style: context.text.body2,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                msg.senderName ?? msg.senderId,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      context.palette.textMuted,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(msg.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      context.palette.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          // Input
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Écrivez votre message...',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                    enabled: !_isSending,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: _isSending
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  PharmaConnectColors
                                                      .accentCyan,
                                                ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.send,
                                          color: context.palette.primary,
                                        ),
                                  onPressed: _isSending ? null : _sendMessage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${date.day}/${date.month}/${date.year}';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}

import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/bot_conversation.dart';
import '../models/knowledge_article.dart';

class BotAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _random = Random();

  // ---- Conversation Management ----

  Future<BotConversation> createConversation(String patientId) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = {
      'id': id,
      'patient_id': patientId,
      'messages': [],
      'status': 'active',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'created_by': SupabaseService().currentUser?.id,
      'updated_by': SupabaseService().currentUser?.id,
    };
    final response = await _client
        .from('bot_conversations')
        .insert(data)
        .select()
        .single();
    return BotConversation.fromJson(response as Map<String, dynamic>);
  }

  Future<BotConversation> getConversation(String id) async {
    final response = await _client
        .from('bot_conversations')
        .select()
        .eq('id', id)
        .single();
    return BotConversation.fromJson(response as Map<String, dynamic>);
  }

  Future<List<BotConversation>> getConversationsForPatient(
    String patientId,
  ) async {
    final response = await _client
        .from('bot_conversations')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => BotConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BotConversation> updateConversation(
    BotConversation conversation,
  ) async {
    final data = conversation
        .copyWith(
          updatedAt: DateTime.now().toUtc(),
          updatedBy: SupabaseService().currentUser?.id,
        )
        .toJson();
    final response = await _client
        .from('bot_conversations')
        .update(data)
        .eq('id', conversation.id)
        .select()
        .single();
    return BotConversation.fromJson(response as Map<String, dynamic>);
  }

  // ---- AI Response Generation ----

  Future<BotMessage> getResponse(
    BotConversation conversation,
    String userMessage,
  ) async {
    // Add user message to conversation
    final userMsg = BotMessage(
      id: _uuid.v4(),
      sender: 'user',
      text: userMessage,
      timestamp: DateTime.now().toUtc(),
    );
    final updatedConv = conversation.copyWith(
      messages: [...conversation.messages, userMsg],
    );
    await updateConversation(updatedConv);

    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 600));

    // Try to find response
    var response = await _findBestResponse(userMessage);

    if (response == null) {
      response = _getFallbackResponse();
    }

    // Create bot message
    final botMsg = BotMessage(
      id: _uuid.v4(),
      sender: 'bot',
      text: response,
      timestamp: DateTime.now().toUtc(),
    );

    // Save bot message
    final finalConv = updatedConv.copyWith(
      messages: [...updatedConv.messages, botMsg],
    );
    await updateConversation(finalConv);

    return botMsg;
  }

  Future<String?> _findBestResponse(String query) async {
    final lowerQuery = query.toLowerCase();

    // Try intent-based matching (fallback)
    final intents = await _getIntents();
    for (final intent in intents) {
      for (final pattern in intent.patterns) {
        if (lowerQuery.contains(pattern.toLowerCase())) {
          return intent.response;
        }
      }
    }

    // Try knowledge base search
    final articles = await _searchKnowledgeBase(query);
    if (articles.isNotEmpty) {
      final article = articles.first;
      await _incrementViewCount(article.id);
      return '${article.title}\n\n${article.content}\n\n[📖 Voir l\'article complet]';
    }

    return null;
  }

  // ---- Knowledge Base ----

  Future<List<dynamic>> _searchKnowledgeBase(String query) async {
    try {
      // Simple keyword search
      final response = await _client
          .from('support_knowledge_articles')
          .select()
          .eq('is_active', true)
          .textSearch('title', query)
          .limit(3);
      return response as List;
    } catch (e) {
      return [];
    }
  }

  Future<void> _incrementViewCount(String articleId) async {
    try {
      await _client.rpc(
        'increment_article_view',
        params: {'article_id': articleId},
      );
    } catch (e) {
      // Silent fail
    }
  }

  String _getFallbackResponse() {
    final fallbacks = [
      'Je comprends votre question. Pouvez-vous reformuler ou préciser ? Je suis là pour vous aider.',
      'Merci pour votre message. Je vais vous rediriger vers un agent humain qui pourra mieux vous assister.',
      'Je ne suis pas sûr d\'avoir bien compris. Pouvez-vous me donner plus de détails ?',
      'Je suis désolé, je ne trouve pas de réponse à votre question. Puis-je vous aider avec autre chose ?',
    ];
    return fallbacks[_random.nextInt(fallbacks.length)];
  }

  // ---- Intents ----

  Future<List<BotIntent>> _getIntents() async {
    try {
      final response = await _client
          .from('bot_intents')
          .select()
          .eq('is_active', true);
      return (response as List)
          .map((e) => BotIntent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BotIntent>> getAllIntents() async {
    return _getIntents();
  }

  Future<BotIntent> createIntent(BotIntent intent) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = intent
        .copyWith(
          id: id,
          createdAt: now,
          updatedAt: now,
          createdBy: SupabaseService().currentUser?.id,
          updatedBy: SupabaseService().currentUser?.id,
        )
        .toJson();
    final response = await _client
        .from('bot_intents')
        .insert(data)
        .select()
        .single();
    return BotIntent.fromJson(response as Map<String, dynamic>);
  }

  Future<BotIntent> updateIntent(BotIntent intent) async {
    final data = intent
        .copyWith(
          updatedAt: DateTime.now().toUtc(),
          updatedBy: SupabaseService().currentUser?.id,
        )
        .toJson();
    final response = await _client
        .from('bot_intents')
        .update(data)
        .eq('id', intent.id)
        .select()
        .single();
    return BotIntent.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteIntent(String id) async {
    await _client.from('bot_intents').delete().eq('id', id);
  }

  // ---- Feedback ----

  Future<void> submitFeedback({
    required String conversationId,
    required int rating,
    String? comment,
    bool? issueResolved,
  }) async {
    await _client.from('bot_feedback').insert({
      'conversation_id': conversationId,
      'rating': rating,
      'comment': comment,
      'issue_resolved': issueResolved,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---- Escalation ----

  Future<BotConversation> escalateConversation(
    String conversationId,
    String reason,
  ) async {
    final conv = await getConversation(conversationId);
    final updated = conv.copyWith(
      status: 'escalated',
      escalationReason: reason,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: SupabaseService().currentUser?.id,
    );
    return updateConversation(updated);
  }

  Future<BotConversation> resolveConversation(String conversationId) async {
    final conv = await getConversation(conversationId);
    final updated = conv.copyWith(
      status: 'resolved',
      resolvedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      updatedBy: SupabaseService().currentUser?.id,
    );
    return updateConversation(updated);
  }

  // ---- Staff (escalated conversations) ----

  Future<List<BotConversation>> getEscalatedConversations() async {
    final response = await _client
        .from('bot_conversations')
        .select()
        .eq('status', 'escalated')
        .order('updated_at', ascending: false);
    return (response as List)
        .map((e) => BotConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BotConversation> addStaffMessage(
    String conversationId,
    String message,
  ) async {
    final conv = await getConversation(conversationId);
    final staffMsg = BotMessage(
      id: _uuid.v4(),
      sender: 'staff',
      text: message,
      timestamp: DateTime.now().toUtc(),
    );
    final updated = conv.copyWith(messages: [...conv.messages, staffMsg]);
    return updateConversation(updated);
  }

  // ---- Knowledge base ----

  Future<List<KnowledgeArticle>> getKnowledgeArticles({String? query}) async {
    try {
      var builder = _client
          .from('support_knowledge_articles')
          .select()
          .eq('is_active', true);
      if (query != null && query.trim().isNotEmpty) {
        builder = builder.textSearch('title', query.trim());
      }
      final response = await builder.order('title');
      return (response as List)
          .map((e) => KnowledgeArticle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load knowledge base: $e');
    }
  }
}

class BotIntent {
  final String id;
  final String intent;
  final List<String> patterns;
  final String response;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const BotIntent({
    required this.id,
    required this.intent,
    required this.patterns,
    required this.response,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  BotIntent copyWith({
    String? id,
    String? intent,
    List<String>? patterns,
    String? response,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return BotIntent(
      id: id ?? this.id,
      intent: intent ?? this.intent,
      patterns: patterns ?? this.patterns,
      response: response ?? this.response,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'intent': intent,
    'patterns': patterns,
    'response': response,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory BotIntent.fromJson(Map<String, dynamic> json) => BotIntent(
    id: json['id'] as String,
    intent: json['intent'] as String,
    patterns: (json['patterns'] as List?)?.cast<String>() ?? [],
    response: json['response'] as String,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );
}

import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/cash_drawer_session.dart';
import '../models/cash_movement.dart';

class CashService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Sessions ----

  Future<CashDrawerSession> openSession({
    required String pharmacyId,
    required String cashierId,
    required int openingBalance,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc(
        'open_cash_drawer',
        params: {
          'p_pharmacy_id': pharmacyId,
          'p_cashier_id': cashierId,
          'p_opening_balance': openingBalance,
          'p_notes': notes,
        },
      );
      final sessionId = response as String;
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session introuvable après ouverture : $sessionId');
      }
      return session;
    } catch (e) {
      throw Exception('Failed to open cash drawer: $e');
    }
  }

  Future<CashDrawerSession> closeSession({
    required String sessionId,
    required int closingBalance,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'close_cash_drawer',
        params: {
          'p_session_id': sessionId,
          'p_closing_balance': closingBalance,
          'p_notes': notes,
        },
      );
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session introuvable après fermeture : $sessionId');
      }
      return session;
    } catch (e) {
      throw Exception('Failed to close cash drawer: $e');
    }
  }

  Future<CashDrawerSession?> getSession(String id) async {
    try {
      final response = await _client
          .from('cash_drawer_sessions')
          .select('*, cashiers:cashier_id(full_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return CashDrawerSession.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load cash session: $e');
    }
  }

  Future<List<CashDrawerSession>> getSessions({
    String? pharmacyId,
    String? cashierId,
    CashSessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client
          .from('cash_drawer_sessions')
          .select('*, cashiers:cashier_id(full_name)');

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (cashierId != null) {
        query = query.eq('cashier_id', cashierId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (fromDate != null) {
        query = query.gte('opened_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('opened_at', toDate.toIso8601String());
      }

      final response = await query.order('opened_at', ascending: false);
      return (response as List)
          .map((e) => CashDrawerSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load cash sessions: $e');
    }
  }

  Future<CashDrawerSession?> getCurrentOpenSession(String pharmacyId) async {
    try {
      final response = await _client
          .from('cash_drawer_sessions')
          .select('*, cashiers:cashier_id(full_name)')
          .eq('pharmacy_id', pharmacyId)
          .eq('status', CashSessionStatus.open.name)
          .maybeSingle();
      if (response == null) return null;
      return CashDrawerSession.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load current cash session: $e');
    }
  }

  // ---- Movements ----

  Future<List<CashMovement>> getMovements(String sessionId) async {
    try {
      final response = await _client
          .from('cash_movements')
          .select()
          .eq('cash_drawer_session_id', sessionId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((e) => CashMovement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load cash movements: $e');
    }
  }

  Future<CashMovement> addMovement({
    required String sessionId,
    required CashMovementType type,
    required int amount,
    String? referenceId,
    String? referenceType,
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = {
        'id': id,
        'cash_drawer_session_id': sessionId,
        'type': type.name,
        'amount': amount,
        'reference_id': referenceId,
        'reference_type': referenceType,
        'notes': notes,
        'created_at': now.toIso8601String(),
        'created_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('cash_movements')
          .insert(data)
          .select()
          .single();
      return CashMovement.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add cash movement: $e');
    }
  }

  // ---- Summary ----

  Future<Map<String, dynamic>> getSessionSummary(String sessionId) async {
    try {
      final response = await _client
          .from('cash_summary')
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();
      if (response == null) return {};
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get cash summary: $e');
    }
  }

  Future<Map<String, dynamic>> getCashReport({
    required String pharmacyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final sessions = await getSessions(
        pharmacyId: pharmacyId,
        fromDate: fromDate,
        toDate: toDate,
      );

      int totalOpening = 0;
      int totalSales = 0;
      int totalRefunds = 0;
      int totalWithdrawals = 0;
      int totalDeposits = 0;
      int totalClosing = 0;

      for (final session in sessions) {
        final summary = await getSessionSummary(session.id);
        totalOpening += session.openingBalance;
        totalSales += (summary['total_sales'] as int? ?? 0);
        totalRefunds += (summary['total_refunds'] as int? ?? 0);
        totalWithdrawals += (summary['total_withdrawals'] as int? ?? 0);
        totalDeposits += (summary['total_deposits'] as int? ?? 0);
        if (session.closingBalance != null) {
          totalClosing += session.closingBalance!;
        }
      }

      return {
        'total_sessions': sessions.length,
        'total_opening': totalOpening,
        'total_sales': totalSales,
        'total_refunds': totalRefunds,
        'total_withdrawals': totalWithdrawals,
        'total_deposits': totalDeposits,
        'total_closing': totalClosing,
        'net_cash':
            totalOpening +
            totalSales -
            totalRefunds -
            totalWithdrawals +
            totalDeposits,
      };
    } catch (e) {
      throw Exception('Failed to get cash report: $e');
    }
  }
}

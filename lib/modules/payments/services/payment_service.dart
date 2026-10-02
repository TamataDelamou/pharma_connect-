import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';
import '../models/wallet.dart';
import '../models/invoice.dart';
import '../../../core/services/supabase_service.dart';

/// C225 / D67 : l'état financier (statut payé, portefeuille, échéances,
/// factures) n'est plus écrit par l'application. L'officine qui encaisse (ou
/// GSG) confirme ou rembourse par des fonctions serveur journalisées ; le
/// patient peut abandonner ou contester. RG-PAY-01.
class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => message;
}

class PaymentService {
  SupabaseClient get _client => SupabaseService().client;

  /// Appel d'une fonction serveur de paiement, erreur rendue lisible.
  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try {
      await _client.rpc(name, params: params);
    } on PostgrestException catch (e) {
      final message = e.message.replaceFirst(RegExp(r'^PAIEMENT: '), '');
      throw PaymentException(
        message.isEmpty
            ? 'Opération refusée.'
            : message[0].toUpperCase() + message.substring(1),
      );
    }
  }

  // Taux
  static const int _feePercent = 1;
  static const int _cashbackPercent = 2;

  // ==================== TRANSACTIONS ====================

  Future<List<Transaction>> getTransactions({
    TransactionStatus? status,
    String? pharmacyId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMethod? method,
    int limit = 50,
  }) async {
    var query = _client.from('transactions').select();

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (pharmacyId != null) {
      query = query.eq('pharmacy_id', pharmacyId);
    }
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (fromDate != null) {
      query = query.gt('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lt('created_at', toDate.toIso8601String());
    }
    if (method != null) {
      query = query.eq('method', method.name);
    }

    final rows = await query.order('created_at', ascending: false).limit(limit);
    return rows.map((row) => Transaction.fromJson(row)).toList();
  }

  Future<Transaction> getTransaction(String id) async {
    final row = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .single();
    return Transaction.fromJson(row);
  }

  Future<int> getTransactionCount({
    TransactionStatus? status,
    String? userId,
  }) async {
    var query = _client.from('transactions').select('id');
    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    final rows = await query;
    return rows.length;
  }

  // ==================== PORTEFEUILLE ====================

  Future<Wallet> getWallet(String userId) async {
    final row = await _client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .single();
    return Wallet.fromJson(row);
  }

  // Bug corrigé (audit Module 8, 29/08/2026) : getWallet() utilisait
  // .single(), qui lève une exception dès qu'aucune ligne n'existe — et
  // aucun trigger d'inscription ni aucune insertion ne crée jamais de ligne
  // wallets pour un nouvel utilisateur (grep sur toutes les migrations :
  // zéro insert into wallets). Le premier appel réel de getWallet/loadWallet
  // pour n'importe quel utilisateur aurait donc toujours échoué.
  // getOrCreateWallet() auto-provisionne un portefeuille à zéro si absent,
  // et devient le point d'entrée utilisé par le provider et par les
  // méthodes d'écriture ci-dessous (topUpWallet, initiateTransaction).
  Future<Wallet> getOrCreateWallet(String userId) async {
    final row = await _client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row != null) return Wallet.fromJson(row);

    final created = await _client
        .from('wallets')
        .insert({
          'user_id': userId,
          'balance': 0,
          'pending_balance': 0,
          'total_earned': 0,
          'total_spent': 0,
          'cashback_available': 0,
          'currency': 'GNF',
          'last_updated': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return Wallet.fromJson(created);
  }

  Future<int> getWalletBalance(String userId) async {
    final wallet = await getOrCreateWallet(userId);
    return wallet.balance;
  }

  /// C225 / D67 : recharge désactivée. Elle créditait le solde depuis
  /// l'application sans aucun paiement réel ; elle reviendra avec le
  /// branchement des opérateurs Mobile Money (confirmation serveur).
  Future<Wallet> topUpWallet({
    required String userId,
    required int amount,
    required PaymentMethod method,
  }) async {
    throw const PaymentException(
      'La recharge du portefeuille sera bientôt disponible.',
    );
  }

  // ==================== INITIATION ====================

  // RG-PAY-01 (Cahier de conception, Critique) : "Aucune commande n'est
  // marquée « payée » tant que la confirmation de l'agrégateur de paiement
  // n'a pas été reçue et vérifiée côté serveur." Cette architecture
  // Flutter+Supabase n'a pas de backend séparé capable de recevoir les
  // webhooks Orange Money/MTN MoMo/Moov Money : la confirmation ci-dessous
  // reste donc un délai simulé côté client, comportement hérité du mock.
  // Non résolu par cet audit — limitation structurelle documentée au
  // registre des écarts (nouvel item D, analogue à D1) plutôt que masquée.
  Future<Transaction> initiateTransaction({
    required String userId,
    required String userPhone,
    required int amount,
    required PaymentMethod method,
    String? reservationId,
    String? deliveryId,
    String? prescriptionId,
    String? pharmacyId,
    String? pharmacyName,
    bool useCashback = false,
  }) async {
    // Bug corrigé (audit Module 8, 29/08/2026) : le cashback à utiliser
    // était recalculé à 2% du montant à chaque paiement, sans jamais être
    // comparé au solde réel wallet.cashbackAvailable — un utilisateur
    // pouvait donc "dépenser" un cashback qu'il n'avait jamais gagné. Le
    // montant réellement déduit est désormais plafonné par le solde
    // effectif du portefeuille.
    final wallet = await getOrCreateWallet(userId);

    final int fee = method == PaymentMethod.gsgWallet
        ? 0
        : (amount * _feePercent) ~/ 100;
    final int potentialCashback =
        (method.isMobileMoney || method == PaymentMethod.gsgWallet)
        ? (amount * _cashbackPercent) ~/ 100
        : 0;
    final int redeemedCashback = useCashback
        ? (potentialCashback < wallet.cashbackAvailable
              ? potentialCashback
              : wallet.cashbackAvailable)
        : 0;
    final int finalAmount = amount + fee - redeemedCashback;

    // Bug corrigé (audit Module 8, 29/08/2026) : aucune vérification de
    // solde ni aucun débit n'existaient pour PaymentMethod.gsgWallet — un
    // paiement par portefeuille pouvait donc être "effectué" avec un solde
    // à zéro, sans jamais débiter quoi que ce soit.
    if (method == PaymentMethod.gsgWallet && wallet.balance < finalAmount) {
      throw Exception(
        'Solde du portefeuille GSG insuffisant pour ce paiement.',
      );
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      userPhone: userPhone,
      amount: amount,
      fee: fee,
      cashback: redeemedCashback,
      finalAmount: finalAmount,
      method: method,
      status: TransactionStatus.processing,
      createdAt: DateTime.now(),
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      reservationId: reservationId,
      deliveryId: deliveryId,
      prescriptionId: prescriptionId,
      transactionReference: 'GSG${const Uuid().v4().substring(0, 8)}',
    );

    await _client.from('transactions').insert(transaction.toJson());

    // Bug corrigé (audit Module 8, 29/08/2026) : "Paiement en plusieurs
    // fois" simulait quand même une confirmation immédiate et facturait la
    // totalité tout de suite — createInstallment() n'était d'ailleurs
    // jamais appelée depuis ce flux (aucun appelant nulle part dans le
    // module). La transaction reste désormais 'processing' : c'est
    // PaymentProvider.initiatePayment qui crée l'échéancier juste après, et
    // payInstallmentByTransaction() qui complète la transaction (et génère
    // la facture) au paiement de la dernière échéance.
    if (method == PaymentMethod.installment) {
      return transaction;
    }

    // C225 / D67 : plus de confirmation simulée. La transaction reste en
    // attente jusqu'à ce que l'officine constate l'encaissement
    // (payment_confirm_transaction) ; le serveur règle alors le
    // portefeuille et produit la facture.
    return transaction;
  }

  /// C225 : confirmation par l'officine qui encaisse (ou GSG).
  Future<Transaction> confirmTransaction(String transactionId) async {
    await _rpc('payment_confirm_transaction', {
      'p_transaction_id': transactionId,
    });
    return getTransaction(transactionId);
  }

  /// C225 : remboursement par l'officine (ou GSG), motif obligatoire.
  Future<Transaction> refundTransaction(
    String transactionId, {
    String? reason,
  }) async {
    await _rpc('payment_refund_transaction', {
      'p_transaction_id': transactionId,
      'p_reason': reason ?? '',
    });
    return getTransaction(transactionId);
  }

  /// C225 : contestation par le patient, motif obligatoire.
  Future<Transaction> markAsDisputed(
    String transactionId, {
    String? reason,
  }) async {
    await _rpc('payment_dispute_transaction', {
      'p_transaction_id': transactionId,
      'p_reason': reason ?? '',
    });
    return getTransaction(transactionId);
  }

  /// C225 : abandon par le patient d'une transaction non encore payée.
  Future<Transaction> cancelTransaction(String transactionId) async {
    await _rpc('payment_cancel_transaction', {
      'p_transaction_id': transactionId,
    });
    return getTransaction(transactionId);
  }

  // ==================== ÉCHÉANCIER ====================

  Future<Installment> createInstallment({
    required String transactionId,
    required int totalAmount,
    required int numberOfPayments,
    required DateTime startDate,
  }) async {
    final int amountPerPayment = totalAmount ~/ numberOfPayments;
    final payments = <InstallmentPayment>[
      for (int i = 0; i < numberOfPayments; i++)
        InstallmentPayment(
          number: i + 1,
          amount: amountPerPayment,
          dueDate: startDate.add(Duration(days: (i + 1) * 30)),
          status: InstallmentPaymentStatus.pending,
        ),
    ];

    final installment = Installment(
      id: const Uuid().v4(),
      transactionId: transactionId,
      totalAmount: totalAmount,
      numberOfPayments: numberOfPayments,
      amountPerPayment: amountPerPayment,
      startDate: startDate,
      payments: payments,
      status: InstallmentStatus.active,
    );

    await _client.from('installments').insert(installment.toJson());
    await _client
        .from('installment_payments')
        .insert(
          payments.map((p) => p.toJson(installmentId: installment.id)).toList(),
        );

    return installment;
  }

  Future<Installment> getInstallmentByTransaction(String transactionId) async {
    final row = await _client
        .from('installments')
        .select('*, installment_payments(*)')
        .eq('transaction_id', transactionId)
        .single();
    return Installment.fromJson(row);
  }

  /// C225 : échéance confirmée par l'officine qui encaisse (ou GSG) ; à la
  /// dernière, le serveur solde l'échéancier, confirme la transaction et
  /// produit la facture.
  Future<Installment> payInstallmentByTransaction(
    String transactionId,
    int paymentNumber,
  ) async {
    await _rpc('payment_confirm_installment', {
      'p_transaction_id': transactionId,
      'p_payment_number': paymentNumber,
    });
    return getInstallmentByTransaction(transactionId);
  }

  // ==================== FACTURES ====================

  // C225 : les factures sont produites par le serveur à la confirmation.

  Future<Invoice?> getInvoice(String transactionId) async {
    final row = await _client
        .from('invoices')
        .select('*, invoice_items(*)')
        .eq('transaction_id', transactionId)
        .maybeSingle();
    return row != null ? Invoice.fromJson(row) : null;
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getPaymentStats(String userId) async {
    final userTransactions = await getTransactions(
      userId: userId,
      limit: 10000,
    );
    final completed = userTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();

    return {
      'totalSpent': completed.fold(0, (sum, t) => sum + t.finalAmount),
      'transactionCount': completed.length,
      'averageAmount': completed.isEmpty
          ? 0
          : completed.fold(0, (sum, t) => sum + t.finalAmount) ~/
                completed.length,
      'mostUsedMethod': _getMostUsedMethod(userTransactions),
      'totalCashback': completed.fold(0, (sum, t) => sum + (t.cashback ?? 0)),
    };
  }

  String _getMostUsedMethod(List<Transaction> transactions) {
    if (transactions.isEmpty) return 'Aucun';
    final counts = <PaymentMethod, int>{};
    for (final t in transactions) {
      counts[t.method] = (counts[t.method] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key.label;
  }
}

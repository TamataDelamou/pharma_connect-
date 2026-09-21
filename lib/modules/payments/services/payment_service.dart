import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';
import '../models/wallet.dart';
import '../models/invoice.dart';
import '../../../core/services/supabase_service.dart';

class PaymentService {
  SupabaseClient get _client => SupabaseService().client;

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

  Future<Wallet> topUpWallet({
    required String userId,
    required int amount,
    required PaymentMethod method,
  }) async {
    final current = await getOrCreateWallet(userId);

    final row = await _client
        .from('wallets')
        .update({
          'balance': current.balance + amount,
          'last_updated': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .select()
        .single();
    final updated = Wallet.fromJson(row);

    final transaction = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      userPhone: '',
      amount: amount,
      fee: 0,
      cashback: 0,
      finalAmount: amount,
      method: method,
      status: TransactionStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      transactionReference: 'TOPUP${const Uuid().v4().substring(0, 8)}',
    );
    await _client.from('transactions').insert(transaction.toJson());

    return updated;
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
      throw Exception('Solde du portefeuille GSG insuffisant pour ce paiement.');
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

    // Simuler la confirmation (comportement hérité du mock — un vrai
    // fournisseur Mobile Money confirmerait via webhook, pas un délai fixe ;
    // voir RG-PAY-01 ci-dessus).
    await Future.delayed(const Duration(seconds: 2));
    final row = await _client
        .from('transactions')
        .update({
          'status': TransactionStatus.completed.name,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transaction.id)
        .select()
        .single();
    final completed = Transaction.fromJson(row);

    await _settleWallet(
      userId: userId,
      method: method,
      finalAmount: finalAmount,
      redeemedCashback: redeemedCashback,
      earnedCashback: potentialCashback,
    );
    await _createInvoice(completed);

    return completed;
  }

  // Bug corrigé (audit Module 8, 29/08/2026) : ni le débit du portefeuille
  // (PaymentMethod.gsgWallet) ni le crédit du cashback gagné n'étaient
  // jamais appliqués nulle part — wallet.balance et wallet.cashbackAvailable
  // restaient donc figés quels que soient les paiements effectués. Ce
  // helper centralise les deux mouvements au moment où une transaction est
  // effectivement complétée (paiement direct ou dernière échéance).
  Future<void> _settleWallet({
    required String userId,
    required PaymentMethod method,
    required int finalAmount,
    required int redeemedCashback,
    required int earnedCashback,
  }) async {
    if (finalAmount == 0 && redeemedCashback == 0 && earnedCashback == 0) {
      return;
    }
    final current = await getOrCreateWallet(userId);
    final int debit = method == PaymentMethod.gsgWallet ? finalAmount : 0;

    await _client
        .from('wallets')
        .update({
          'balance': current.balance - debit,
          'cashback_available':
              current.cashbackAvailable - redeemedCashback + earnedCashback,
          'total_spent': current.totalSpent + finalAmount,
          'total_earned': current.totalEarned + earnedCashback,
          'last_updated': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  Future<Transaction> confirmTransaction(String transactionId) async {
    final row = await _client
        .from('transactions')
        .update({
          'status': TransactionStatus.completed.name,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select()
        .single();
    final updated = Transaction.fromJson(row);
    await _createInvoice(updated);
    return updated;
  }

  Future<Transaction> refundTransaction(
    String transactionId, {
    String? reason,
  }) async {
    final row = await _client
        .from('transactions')
        .update({
          'status': TransactionStatus.refunded.name,
          'refunded_at': DateTime.now().toIso8601String(),
          'notes': reason,
        })
        .eq('id', transactionId)
        .select()
        .single();
    return Transaction.fromJson(row);
  }

  Future<Transaction> markAsDisputed(
    String transactionId, {
    String? reason,
  }) async {
    final row = await _client
        .from('transactions')
        .update({'status': TransactionStatus.disputed.name, 'notes': reason})
        .eq('id', transactionId)
        .select()
        .single();
    return Transaction.fromJson(row);
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

  Future<Installment> _getInstallmentById(String installmentId) async {
    final row = await _client
        .from('installments')
        .select('*, installment_payments(*)')
        .eq('id', installmentId)
        .single();
    return Installment.fromJson(row);
  }

  // Bug corrigé (audit Module 8, 29/08/2026) : cette méthode s'appelait
  // getInstallment(installmentId) et cherchait par installments.id — mais
  // payment_screen.dart navigue vers '/payments/installment/${transaction.id}'
  // et installment_plan_screen.dart transmet cet identifiant de
  // TRANSACTION, jamais l'id propre de l'échéancier. La recherche ne
  // trouvait donc jamais rien ("Aucun échéancier trouvé" systématique).
  // Résolution : chercher par transaction_id, l'identifiant réellement
  // disponible côté écran, sans changer la signature attendue par
  // installment_plan_screen.dart / PaymentProvider.
  Future<Installment> getInstallmentByTransaction(String transactionId) async {
    final row = await _client
        .from('installments')
        .select('*, installment_payments(*)')
        .eq('transaction_id', transactionId)
        .single();
    return Installment.fromJson(row);
  }

  Future<Installment> payInstallmentByTransaction(
    String transactionId,
    int paymentNumber,
  ) async {
    final installment = await getInstallmentByTransaction(transactionId);

    await _client
        .from('installment_payments')
        .update({
          'status': InstallmentPaymentStatus.paid.name,
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('installment_id', installment.id)
        .eq('payment_number', paymentNumber);

    final updated = await _getInstallmentById(installment.id);
    if (updated.paidCount == updated.numberOfPayments) {
      await _client
          .from('installments')
          .update({
            'status': InstallmentStatus.completed.name,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', installment.id);
      // Bug corrigé (audit Module 8, 29/08/2026) : la transaction parente
      // restait indéfiniment 'processing' même une fois l'échéancier
      // intégralement soldé — confirmTransaction() génère aussi la facture
      // (_createInvoice), jusqu'ici jamais produite pour un paiement en
      // plusieurs fois.
      await confirmTransaction(transactionId);
      return getInstallmentByTransaction(transactionId);
    }

    return updated;
  }

  // ==================== FACTURES ====================

  Future<void> _createInvoice(Transaction transaction) async {
    final invoice = Invoice(
      id: const Uuid().v4(),
      transactionId: transaction.id,
      invoiceNumber: 'FAC${const Uuid().v4().substring(0, 8)}',
      pharmacyName: transaction.pharmacyName ?? 'Pharmacie',
      pharmacyAddress: '123 Rue du Commerce, Conakry',
      pharmacyPhone: '+224622334455',
      patientName: transaction.userId,
      patientAddress: 'Adresse patient',
      patientPhone: transaction.userPhone,
      patientEmail: 'patient@email.com',
      issuedAt: DateTime.now(),
      items: [
        InvoiceItem(
          id: const Uuid().v4(),
          productName: 'Médicaments',
          quantity: 1,
          unitPrice: transaction.amount,
          total: transaction.amount,
          dosage: 'N/A',
        ),
      ],
      subtotal: transaction.amount,
      tax: transaction.fee ?? 0,
      discount: transaction.cashback ?? 0,
      total: transaction.finalAmount,
      status: 'paid',
    );

    await _client.from('invoices').insert(invoice.toJson());
    await _client
        .from('invoice_items')
        .insert(
          invoice.items.map((i) => i.toJson(invoiceId: invoice.id)).toList(),
        );
  }

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
    final userTransactions = await getTransactions(userId: userId, limit: 10000);
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

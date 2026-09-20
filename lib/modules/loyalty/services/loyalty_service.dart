import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_transaction.dart';
import '../models/loyalty_reward.dart';

class LoyaltyService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Accounts ----

  Future<LoyaltyAccount?> getAccount(
    String patientId,
    String pharmacyId,
  ) async {
    try {
      final response = await _client
          .from('loyalty_accounts')
          .select(
            '*, patients:patient_id(full_name), pharmacies:pharmacy_id(name), programs:program_id(name)',
          )
          .eq('patient_id', patientId)
          .eq('pharmacy_id', pharmacyId)
          .maybeSingle();
      if (response == null) return null;
      return LoyaltyAccount.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load loyalty account: $e');
    }
  }

  Future<LoyaltyAccount> createAccount(LoyaltyAccount account) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = account
          .copyWith(
            id: newId,
            pointsBalance: 0,
            totalPointsEarned: 0,
            totalPointsRedeemed: 0,
            tier: 'bronze',
            joinedAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'pharmacy_name' ||
            key == 'program_name' ||
            key == 'patients' ||
            key == 'pharmacies' ||
            key == 'programs',
      );

      final response = await _client
          .from('loyalty_accounts')
          .insert(data)
          .select()
          .single();
      return LoyaltyAccount.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create loyalty account: $e');
    }
  }

  /// Audit Module 16 (FID, 29/08/2026), correctif de compilation (bug 1/3
  /// de ce module) : extrait ici depuis `LoyaltyProvider.loadAccount()`, qui
  /// interrogeait directement un champ `_client` jamais défini dans la
  /// classe `LoyaltyProvider` (`Undefined name '_client'`) — accès direct à
  /// Supabase depuis un provider, en dehors de la couche service, seul
  /// endroit du module où ce motif apparaissait. Retourne l'id du premier
  /// programme de fidélité actif d'une officine, ou `null` si aucun.
  Future<String?> getActiveProgramId(String pharmacyId) async {
    try {
      final response = await _client
          .from('loyalty_programs')
          .select('id')
          .eq('pharmacy_id', pharmacyId)
          .eq('is_active', true)
          .maybeSingle();
      return (response as Map<String, dynamic>?)?['id'] as String?;
    } catch (e) {
      throw Exception('Failed to load active loyalty program: $e');
    }
  }

  /// Audit Module 16 (FID, 29/08/2026) : liste les comptes fidélité du
  /// patient, toutes officines confondues — `loyalty_accounts` n'a qu'une
  /// contrainte d'unicité par (patient_id, pharmacy_id), un patient peut
  /// donc avoir un compte dans plusieurs officines. Utilisé par le nouvel
  /// écran de sélection d'officine (`LoyaltyPharmacySelectScreen`).
  Future<List<LoyaltyAccount>> getMyAccounts(String patientId) async {
    try {
      final response = await _client
          .from('loyalty_accounts')
          .select('*, pharmacies:pharmacy_id(name)')
          .eq('patient_id', patientId)
          .order('joined_at', ascending: false);
      return (response as List)
          .map((e) => LoyaltyAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load loyalty accounts: $e');
    }
  }

  /// Audit Module 16 (FID, 29/08/2026) : officines actives, pour le
  /// sélecteur d'officine (rejoindre un nouveau programme de fidélité).
  /// `pharmacies_select_authenticated` (Module 1) rend déjà cette table
  /// lisible par tout compte authentifié — aucune policy nouvelle requise.
  Future<List<Map<String, dynamic>>> getActivePharmacies() async {
    try {
      final response = await _client
          .from('pharmacies')
          .select('id, name, address')
          .eq('status', 'active')
          .order('name', ascending: true)
          .limit(100);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load pharmacies: $e');
    }
  }

  // ---- Transactions ----

  Future<List<LoyaltyTransaction>> getTransactions(String accountId) async {
    try {
      final response = await _client
          .from('loyalty_transactions')
          .select()
          .eq('account_id', accountId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<LoyaltyTransaction> addTransaction(
    LoyaltyTransaction transaction,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = transaction
          .copyWith(
            id: newId,
            createdAt: now,
            createdBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('loyalty_transactions')
          .insert(data)
          .select()
          .single();
      return LoyaltyTransaction.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<int> earnPoints({
    required String accountId,
    required int amount,
    String? referenceId,
    String? description,
  }) async {
    try {
      // Get current balance
      final account = await _client
          .from('loyalty_accounts')
          .select('points_balance')
          .eq('id', accountId)
          .single();
      final currentBalance =
          (account as Map<String, dynamic>)['points_balance'] as int? ?? 0;

      final transaction = LoyaltyTransaction(
        id: '',
        accountId: accountId,
        transactionType: 'earn',
        amount: amount,
        pointsBalanceAfter: currentBalance + amount,
        referenceId: referenceId,
        description: description ?? 'Points gagnés',
        createdAt: DateTime.now().toUtc(),
      );
      await addTransaction(transaction);
      return currentBalance + amount;
    } catch (e) {
      throw Exception('Failed to earn points: $e');
    }
  }

  Future<int> redeemPoints({
    required String accountId,
    required int amount,
    String? referenceId,
    String? description,
  }) async {
    try {
      final account = await _client
          .from('loyalty_accounts')
          .select('points_balance')
          .eq('id', accountId)
          .single();
      final currentBalance =
          (account as Map<String, dynamic>)['points_balance'] as int? ?? 0;

      if (currentBalance < amount) {
        throw Exception('Points insuffisants');
      }

      final transaction = LoyaltyTransaction(
        id: '',
        accountId: accountId,
        transactionType: 'redeem',
        amount: -amount,
        pointsBalanceAfter: currentBalance - amount,
        referenceId: referenceId,
        description: description ?? 'Points utilisés',
        createdAt: DateTime.now().toUtc(),
      );
      await addTransaction(transaction);
      return currentBalance - amount;
    } catch (e) {
      throw Exception('Failed to redeem points: $e');
    }
  }

  // ---- Rewards ----

  Future<List<LoyaltyReward>> getRewards(String pharmacyId) async {
    try {
      final response = await _client
          .from('loyalty_rewards')
          .select()
          .eq('pharmacy_id', pharmacyId)
          .eq('is_active', true)
          .order('points_required', ascending: true);
      return (response as List)
          .map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load rewards: $e');
    }
  }

  Future<LoyaltyReward> createReward(LoyaltyReward reward) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = reward
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('loyalty_rewards')
          .insert(data)
          .select()
          .single();
      return LoyaltyReward.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create reward: $e');
    }
  }

  // ---- Referrals ----

  Future<void> createReferral(
    String referrerId,
    String referredId,
    String pharmacyId,
  ) async {
    try {
      await _client.from('loyalty_referrals').insert({
        'referrer_patient_id': referrerId,
        'referred_patient_id': referredId,
        'pharmacy_id': pharmacyId,
        'status': 'pending',
        'referral_code': _uuid.v4().substring(0, 8).toUpperCase(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'created_by': SupabaseService().currentUser?.id,
      });
    } catch (e) {
      throw Exception('Failed to create referral: $e');
    }
  }
}

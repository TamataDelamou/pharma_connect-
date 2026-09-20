import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/insurance_company.dart';
import '../models/insurance_enrollment.dart';
import '../models/reimbursement_tracking.dart';

class InsuranceService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Companies ----

  Future<List<InsuranceCompany>> getCompanies({bool? isActive}) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('insurance_companies').select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => InsuranceCompany.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load insurance companies: $e');
    }
  }

  Future<InsuranceCompany?> getCompany(String id) async {
    try {
      final response = await _client
          .from('insurance_companies')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return InsuranceCompany.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load insurance company: $e');
    }
  }

  // ---- Enrollments ----

  Future<List<InsuranceEnrollment>> getEnrollmentsForPatient(
    String patientId,
  ) async {
    try {
      // ASR-6 (audit Module 24) : l'embed d'origine ('companies:plans!inner(company_id(name))')
      // utilisait 'plans' comme indice de relation, qui ne correspond ni à la colonne FK
      // (plan_id) ni à la table cible (insurance_plans) — PostgREST ne peut pas résoudre
      // cet indice. Corrigé en embed imbriqué : plans -> companies (via company_id, FK réelle
      // de insurance_plans vers insurance_companies). Voir InsuranceEnrollment.fromJson pour la
      // lecture correspondante (désormais imbriquée sous plans.companies).
      final response = await _client
          .from('insurance_enrollments')
          .select(
            '*, plans:plan_id(name, companies:company_id(id, name))',
          )
          .eq('patient_id', patientId)
          .order('start_date', ascending: false);
      return (response as List)
          .map((e) => InsuranceEnrollment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load enrollments: $e');
    }
  }

  Future<InsuranceEnrollment?> getEnrollment(String id) async {
    try {
      final response = await _client
          .from('insurance_enrollments')
          .select(
            '*, plans:plan_id(name, companies:company_id(id, name))',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return InsuranceEnrollment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load enrollment: $e');
    }
  }

  Future<InsuranceEnrollment> createEnrollment(
    InsuranceEnrollment enrollment,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = enrollment
          .copyWith(
            id: newId,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'plan_name' ||
            key == 'company_name' ||
            key == 'company_id' ||
            key == 'patient_name' ||
            key == 'plans' ||
            key == 'companies' ||
            key == 'patients',
      );

      final response = await _client
          .from('insurance_enrollments')
          .insert(data)
          .select()
          .single();
      return InsuranceEnrollment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create enrollment: $e');
    }
  }

  Future<InsuranceEnrollment> updateEnrollment(
    InsuranceEnrollment enrollment,
  ) async {
    try {
      final data = enrollment
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'plan_name' ||
            key == 'company_name' ||
            key == 'company_id' ||
            key == 'patient_name' ||
            key == 'plans' ||
            key == 'companies' ||
            key == 'patients',
      );

      final response = await _client
          .from('insurance_enrollments')
          .update(data)
          .eq('id', enrollment.id)
          .select()
          .single();
      return InsuranceEnrollment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update enrollment: $e');
    }
  }

  Future<void> deleteEnrollment(String id) async {
    try {
      await _client.from('insurance_enrollments').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete enrollment: $e');
    }
  }

  // ---- Coverage Calculation ----

  Future<Map<String, dynamic>> calculateCoverage({
    required String enrollmentId,
    required int amount,
    String? procedureType,
  }) async {
    try {
      final enrollment = await getEnrollment(enrollmentId);
      if (enrollment == null) {
        return {'error': 'Enrollment not found'};
      }

      // Get plan details
      final planResponse = await _client
          .from('insurance_plans')
          .select()
          .eq('id', enrollment.planId)
          .single();

      final coverageDetails =
          planResponse['coverage_details'] as Map<String, dynamic>? ?? {};

      // Determine coverage percentage
      int coveragePct = enrollment.coveragePercentage ?? 0;
      if (coveragePct == 0 && procedureType != null) {
        coveragePct = (coverageDetails[procedureType] as int?) ?? 0;
      }
      if (coveragePct == 0) {
        coveragePct = (coverageDetails['default'] as int?) ?? 0;
      }

      final coveredAmount = (amount * coveragePct / 100).round();
      final patientResponsibility = amount - coveredAmount;

      // ASR-5 (audit Module 24) : le plafond restant était auparavant toujours
      // égal au plafond annuel complet (aucun suivi de consommation, cf. RG-ASR-01
      // qui exige un calcul exact de la part prise en charge). Corrigé en sommant
      // la consommation déjà validée de l'année civile en cours (insurance_claims
      // au statut 'approved'/'partially_approved'/'paid' pour cette adhésion),
      // puis en soustrayant du plafond annuel — sans jamais descendre sous 0.
      int? remainingLimit;
      if (enrollment.annualLimit != null) {
        final yearStart = DateTime(DateTime.now().year, 1, 1).toIso8601String();
        final claimsResponse = await _client
            .from('insurance_claims')
            .select('covered_amount')
            .eq('enrollment_id', enrollmentId)
            .inFilter('status', ['approved', 'partially_approved', 'paid'])
            .gte('submitted_at', yearStart);
        final consumedThisYear = (claimsResponse as List).fold<int>(
          0,
          (sum, row) =>
              sum + (((row as Map<String, dynamic>)['covered_amount'] as int?) ?? 0),
        );
        remainingLimit = (enrollment.annualLimit! - consumedThisYear);
        if (remainingLimit < 0) remainingLimit = 0;
      }

      return {
        'totalAmount': amount,
        'coveragePercentage': coveragePct,
        'coveredAmount': coveredAmount,
        'patientResponsibility': patientResponsibility,
        'annualLimit': enrollment.annualLimit,
        'remainingLimit': remainingLimit,
      };
    } catch (e) {
      throw Exception('Failed to calculate coverage: $e');
    }
  }

  // ---- Reimbursement Tracking ----

  // ASR-4 (audit Module 24, Étape 2/3, 30/08/2026) : lecture réelle du suivi
  // de remboursement d'un sinistre, remplaçant les données simulées codées
  // en dur dans ReimbursementStatusScreen._loadData(). Le schéma actuel
  // (20260828022000_reimbursement_tracking.sql) ne porte aucune contrainte
  // d'unicité sur reimbursement_tracking.claim_id — au plus une ligne de
  // suivi par sinistre est le cas d'usage prévu (une demande de
  // remboursement suit un cycle de vie linéaire unique), mais rien n'empêche
  // en théorie plusieurs lignes ; .maybeSingle() lèvera une erreur explicite
  // si ce cas survenait plutôt que de retourner silencieusement la mauvaise
  // ligne — préférable à un `.limit(1)` muet.
  Future<ReimbursementTracking?> getReimbursementForClaim(
    String claimId,
  ) async {
    try {
      final response = await _client
          .from('reimbursement_tracking')
          .select()
          .eq('claim_id', claimId)
          .maybeSingle();
      if (response == null) return null;
      return ReimbursementTracking.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load reimbursement tracking: $e');
    }
  }
}

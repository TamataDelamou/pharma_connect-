import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/traceable_batch.dart';
import '../models/batch_status.dart';
import '../models/batch_movement.dart';
import '../models/cold_chain_record.dart';
import '../models/verification_result.dart';
import '../../../core/services/supabase_service.dart';

class TraceabilityService {
  SupabaseClient get _client => SupabaseService().client;

  static const _batchSelect =
      '*, batch_movements(*), cold_chain_records(*), certificates(*)';

  Future<List<TraceableBatch>> getBatches({
    BatchStatus? status,
    String? productId,
    bool? isRecalled,
    bool? isCounterfeit,
  }) async {
    var query = _client.from('traceable_batches').select(_batchSelect);

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    if (isRecalled != null) {
      query = query.eq('is_recalled', isRecalled);
    }
    if (isCounterfeit != null) {
      query = query.eq('is_counterfeit', isCounterfeit);
    }

    final rows = await query;
    return rows.map((row) => TraceableBatch.fromJson(row)).toList();
  }

  Future<TraceableBatch> getBatch(String id) async {
    final row = await _client
        .from('traceable_batches')
        .select(_batchSelect)
        .eq('id', id)
        .single();
    return TraceableBatch.fromJson(row);
  }

  Future<TraceableBatch?> getBatchBySerialNumber(String serialNumber) async {
    final row = await _client
        .from('traceable_batches')
        .select(_batchSelect)
        .eq('serial_number', serialNumber)
        .maybeSingle();
    return row != null ? TraceableBatch.fromJson(row) : null;
  }

  Future<TraceableBatch?> getBatchByBatchNumber(String batchNumber) async {
    final row = await _client
        .from('traceable_batches')
        .select(_batchSelect)
        .eq('batch_number', batchNumber)
        .maybeSingle();
    return row != null ? TraceableBatch.fromJson(row) : null;
  }

  Future<List<BatchMovement>> getMovements(String batchId) async {
    final rows = await _client
        .from('batch_movements')
        .select()
        .eq('batch_id', batchId)
        .order('timestamp', ascending: false);
    return rows.map((row) => BatchMovement.fromJson(row)).toList();
  }

  Future<List<ColdChainRecord>> getColdChainRecords(String batchId) async {
    final rows = await _client
        .from('cold_chain_records')
        .select()
        .eq('batch_id', batchId)
        .order('timestamp', ascending: false);
    return rows.map((row) => ColdChainRecord.fromJson(row)).toList();
  }

  // ==================== VÉRIFICATION ====================

  Future<VerificationResult> verifyProduct({
    required String serialNumber,
    required String gtin,
    String? verifiedBy,
  }) async {
    final batch = await getBatchBySerialNumber(serialNumber);
    // verified_by référence auth.users(id) : seul l'utilisateur authentifié
    // réel est enregistré, jamais un libellé libre passé par l'appelant.
    final verifierId = SupabaseService().currentUser?.id;

    late VerificationResult result;

    if (batch == null) {
      result = VerificationResult(
        batchId: 'unknown',
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: false,
        isCounterfeit: false,
        isRecalled: false,
        isValid: false,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        message: 'Aucun produit trouvé avec ce numéro de série',
        status: VerificationStatus.invalid,
      );
    } else if (batch.gtin != gtin) {
      result = VerificationResult(
        batchId: batch.id,
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: false,
        isCounterfeit: true,
        isRecalled: batch.isRecalled,
        isValid: false,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        productName: batch.productName,
        batchNumber: batch.batchNumber,
        manufacturingDate: batch.manufacturingDate,
        expiryDate: batch.expiryDate,
        manufacturer: batch.manufacturer,
        message:
            'GTIN ne correspond pas au numéro de série - Contrefaçon suspectée',
        status: VerificationStatus.counterfeit,
      );
    } else if (batch.isRecalled) {
      result = VerificationResult(
        batchId: batch.id,
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: true,
        isCounterfeit: false,
        isRecalled: true,
        isValid: true,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        productName: batch.productName,
        batchNumber: batch.batchNumber,
        manufacturingDate: batch.manufacturingDate,
        expiryDate: batch.expiryDate,
        manufacturer: batch.manufacturer,
        message: '⚠️ Ce produit fait l\'objet d\'un rappel : ${batch.recallReason}',
        status: VerificationStatus.recalled,
      );
    } else {
      result = VerificationResult(
        batchId: batch.id,
        serialNumber: serialNumber,
        gtin: gtin,
        isAuthentic: true,
        isCounterfeit: false,
        isRecalled: false,
        isValid: true,
        timestamp: DateTime.now(),
        verifiedBy: verifiedBy,
        productName: batch.productName,
        batchNumber: batch.batchNumber,
        manufacturingDate: batch.manufacturingDate,
        expiryDate: batch.expiryDate,
        manufacturer: batch.manufacturer,
        message: '✅ Produit authentique',
        status: VerificationStatus.authentic,
      );
    }

    // Chaque scan est journalisé, quelle que soit l'issue — c'est la donnée
    // de pharmacovigilance (détection de contrefaçon par scans répétés sur
    // un même numéro de série), pas seulement un résultat d'écran.
    final scan = {...result.toJson(), 'verified_by': verifierId};
    await _client.from('verification_scans').insert(scan);

    return result;
  }

  // ==================== HISTORIQUE ====================

  Future<List<VerificationResult>> getVerificationHistory(
    String serialNumber,
  ) async {
    final rows = await _client
        .from('verification_scans')
        .select()
        .eq('serial_number', serialNumber)
        .order('timestamp', ascending: false);
    return rows.map((row) => VerificationResult.fromJson(row)).toList();
  }

  // ==================== RAPPEL ====================

  Future<TraceableBatch> recallBatch(
    String batchId, {
    required String reason,
    String? notes,
  }) async {
    final row = await _client
        .from('traceable_batches')
        .update({
          'is_recalled': true,
          'recalled_at': DateTime.now().toIso8601String(),
          'recall_reason': reason,
          'status': BatchStatus.recalled.name,
          'notes': notes,
        })
        .eq('id', batchId)
        .select(_batchSelect)
        .single();
    return TraceableBatch.fromJson(row);
  }

  Future<TraceableBatch> updateBatchStatus(
    String batchId,
    BatchStatus newStatus, {
    String? notes,
  }) async {
    final row = await _client
        .from('traceable_batches')
        .update({'status': newStatus.name, 'notes': notes})
        .eq('id', batchId)
        .select(_batchSelect)
        .single();
    return TraceableBatch.fromJson(row);
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getStatistics() async {
    final batches = await getBatches();

    return {
      'totalBatches': batches.length,
      'activeBatches': batches.where((b) => b.isActive).length,
      'recalledBatches': batches.where((b) => b.isRecalled).length,
      'counterfeitDetected': batches.where((b) => b.isCounterfeit).length,
      'authenticated': batches.where((b) => b.isAuthenticated).length,
      'byStatus': {
        for (final status in BatchStatus.values)
          status.label: batches.where((b) => b.status == status).length,
      },
    };
  }
}

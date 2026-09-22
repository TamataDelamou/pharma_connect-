import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/health_record_summary.dart';
import '../models/health_record.dart';

class HealthRecordAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  Future<Map<String, dynamic>> generateSummary(HealthRecord record) async {
    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 1));

    // Build structured data from record
    final structured = {
      'allergies': record.allergies.map((a) => a.name).toList(),
      'conditions': record.medicalConditions.map((c) => c.name).toList(),
      'medications': record.medications.map((m) => m.name).toList(),
      'vaccinations': record.vaccinations.map((v) => v.name).toList(),
      'vitals': {
        if (record.bloodType != null) 'blood_type': record.bloodType,
        if (record.height != null) 'height': record.height,
        if (record.weight != null) 'weight': record.weight,
      },
    };

    // Extract critical points
    final critical = <Map<String, dynamic>>[];
    for (final allergy in record.allergies) {
      if (allergy.severity == 'severe' || allergy.severity == 'moderate') {
        critical.add({
          'type': 'allergy',
          'description': 'Allergie à ${allergy.name}',
          'severity': allergy.severity ?? 'unknown',
        });
      }
    }
    for (final condition in record.medicalConditions) {
      if (condition.status == 'active') {
        critical.add({
          'type': 'condition',
          'description': condition.name,
          'status': condition.status,
        });
      }
    }

    // Generate summary text
    final summary = _buildSummary(record, structured, critical);

    return {
      'summary': summary,
      'structured_data': structured,
      'critical_points': critical,
    };
  }

  String _buildSummary(
    HealthRecord record,
    Map<String, dynamic> structured,
    List<Map<String, dynamic>> critical,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Résumé médical du patient');

    if (critical.isNotEmpty) {
      buffer.writeln('\n⚠️ POINTS CRITIQUES :');
      for (final point in critical) {
        buffer.writeln(
          '  - ${point['description']} (${point['severity'] ?? point['status'] ?? ''})',
        );
      }
    }

    if (record.medicalConditions.isNotEmpty) {
      buffer.writeln('\n🩺 ANTÉCÉDENTS MÉDICAUX :');
      for (final condition in record.medicalConditions) {
        buffer.writeln(
          '  - ${condition.name} (${condition.status ?? 'actif'})',
        );
      }
    }

    if (record.allergies.isNotEmpty) {
      buffer.writeln('\n⚠️ ALLERGIES :');
      for (final allergy in record.allergies) {
        buffer.writeln(
          '  - ${allergy.name} (${allergy.severity ?? 'non spécifié'})',
        );
      }
    }

    if (record.medications.isNotEmpty) {
      buffer.writeln('\n💊 TRAITEMENTS EN COURS :');
      for (final med in record.medications) {
        buffer.writeln(
          '  - ${med.name} ${med.dosage ?? ''} ${med.frequency ?? ''}',
        );
      }
    }

    if (record.vaccinations.isNotEmpty) {
      buffer.writeln('\n💉 VACCINATIONS :');
      for (final vac in record.vaccinations) {
        buffer.writeln(
          '  - ${vac.name} (${vac.date != null ? vac.date!.year : ''})',
        );
      }
    }

    if (record.bloodType != null ||
        record.height != null ||
        record.weight != null) {
      buffer.writeln('\n📊 SIGNES VITAUX :');
      if (record.bloodType != null)
        buffer.writeln('  - Groupe sanguin : ${record.bloodType}');
      if (record.height != null)
        buffer.writeln('  - Taille : ${record.height} cm');
      if (record.weight != null)
        buffer.writeln('  - Poids : ${record.weight} kg');
    }

    if (record.notes != null && record.notes!.isNotEmpty) {
      buffer.writeln('\n📝 NOTES :');
      buffer.writeln('  ${record.notes}');
    }

    return buffer.toString();
  }

  Future<HealthRecordSummary> saveSummary(
    String healthRecordId,
    Map<String, dynamic> analysis,
  ) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = {
      'id': id,
      'health_record_id': healthRecordId,
      'summary': analysis['summary'] as String,
      'structured_data': analysis['structured_data'],
      'critical_points': analysis['critical_points'],
      'generated_at': now.toIso8601String(),
      'created_by': SupabaseService().currentUser?.id,
    };
    final response = await _client
        .from('health_record_summaries')
        .insert(data)
        .select()
        .single();
    return HealthRecordSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<HealthRecordSummary?> getLatestSummary(String healthRecordId) async {
    try {
      final response = await _client
          .from('health_record_summaries')
          .select()
          .eq('health_record_id', healthRecordId)
          .order('generated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return HealthRecordSummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

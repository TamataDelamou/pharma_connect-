import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import '../providers/health_record_provider.dart';
import '../widgets/health_record_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HealthRecordListScreen extends StatefulWidget {
  final String? patientId; // if null, use current user

  const HealthRecordListScreen({super.key, this.patientId});

  @override
  State<HealthRecordListScreen> createState() => _HealthRecordListScreenState();
}

class _HealthRecordListScreenState extends State<HealthRecordListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HealthRecordProvider>();
      final patientId = widget.patientId ?? SupabaseService().currentUser?.id;
      if (patientId != null) {
        provider.loadRecords(patientId);
      }
    });
  }

  /// C219 : vrai pour le dossier de l'utilisateur lui-même ; faux quand un
  /// professionnel consulte le dossier d'un patient (lien de soin ou accès
  /// d'urgence, lecture seule).
  bool get _isOwnRecord {
    final userId = SupabaseService().currentUser?.id;
    return widget.patientId == null || widget.patientId == userId;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordProvider>();
    final isOwnRecord = _isOwnRecord;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header. C233 : sur téléphone, le titre prend toute la largeur
            // et les actions passent en dessous (HeaderRow).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwnRecord
                        ? 'Dossier de santé'
                        : 'Dossier de santé du patient',
                    style: context.text.heading1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOwnRecord
                        ? 'Consultez et gérez vos informations médicales'
                        : 'Consultation en lecture seule, enregistrée et '
                              'visible par le patient',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (isOwnRecord) ...[
                  // C219 / D63 : le patient voit qui a ouvert son dossier en
                  // urgence et peut mettre fin à un accès en cours.
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/healthrecord/emergency-access'),
                    icon: const Icon(Icons.emergency),
                    label: const Text('Accès d\'urgence'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.palette.primary),
                      foregroundColor: context.palette.primary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/healthrecord/edit'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(child: _buildContent(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HealthRecordProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.palette.danger),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                provider.clearError();
                final patientId =
                    widget.patientId ?? SupabaseService().currentUser?.id;
                if (patientId != null) provider.loadRecords(patientId);
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            const SizedBox(height: 16),
            Text('Aucun dossier de santé', style: context.text.heading3),
            const SizedBox(height: 8),
            Text(
              _isOwnRecord
                  ? 'Créez votre premier dossier pour suivre vos informations médicales'
                  : 'Aucun dossier accessible pour ce patient (lien de soin '
                        'ou accès d\'urgence requis)',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.records.length,
      itemBuilder: (context, index) {
        final record = provider.records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HealthRecordCard(
            record: record,
            onTap: () => context.push('/healthrecord/${record.id}'),
          ),
        );
      },
    );
  }
}

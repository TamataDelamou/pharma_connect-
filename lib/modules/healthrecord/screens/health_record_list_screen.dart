import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../providers/health_record_provider.dart';
import '../widgets/health_record_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dossier de santé',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Consultez et gérez vos informations médicales',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/healthrecord/edit'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: PharmaConnectColors.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun dossier de santé',
              style: PharmaConnectTypography.heading3,
            ),
            SizedBox(height: 8),
            Text(
              'Créez votre premier dossier pour suivre vos informations médicales',
              style: PharmaConnectTypography.body2,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../providers/prescription_provider.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String patientId;

  const PatientHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Historique du patient',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultez l\'historique des ordonnances du patient',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.prescriptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune ordonnance pour ce patient',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.prescriptions.length,
                      itemBuilder: (context, index) {
                        final prescription = provider.prescriptions[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: prescription.statusColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                prescription.statusLabel[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: prescription.statusColor,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '#${prescription.id}',
                            style: PharmaConnectTypography.body1,
                          ),
                          subtitle: Text(
                            '${prescription.items.length} médicaments • ${_formatDate(prescription.uploadedAt)}',
                            style: PharmaConnectTypography.body2,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: prescription.statusColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prescription.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: prescription.statusColor,
                              ),
                            ),
                          ),
                          onTap: () {
                            context.push('/prescriptions/${prescription.id}');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

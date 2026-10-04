import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../providers/prescription_provider.dart';
import '../../../core/theme/palette.dart';

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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Historique du patient',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text(
              'Consultez l\'historique des ordonnances du patient',
              style: context.text.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  // Même garde qu'à prescription_list_screen.dart (audit
                  // Module 5) : un repli hors-ligne réussi renseigne aussi
                  // `error` (message informatif) — sans `&& ...isEmpty`, cet
                  // écran masquerait la liste mise en cache derrière un
                  // message d'erreur plein écran.
                  : provider.error != null && provider.prescriptions.isEmpty
                  ? Center(
                      child: Text(
                        'Erreur : ${provider.error}',
                        style: context.text.body2.copyWith(
                          color: context.palette.danger,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : provider.prescriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune ordonnance pour ce patient',
                            style: context.text.body2,
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
                              color: prescription.statusColor
                                  .of(context.palette)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                prescription.statusLabel[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: prescription.statusColor.of(
                                    context.palette,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '#${prescription.id}',
                            style: context.text.body1,
                          ),
                          subtitle: Text(
                            '${prescription.items.length} médicaments • ${_formatDate(prescription.uploadedAt)}',
                            style: context.text.body2,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: prescription.statusColor
                                  .of(context.palette)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prescription.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: prescription.statusColor.of(
                                  context.palette,
                                ),
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

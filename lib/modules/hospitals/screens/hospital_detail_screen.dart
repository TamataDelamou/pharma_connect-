import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/hospitals_provider.dart';

class HospitalDetailScreen extends StatefulWidget {
  final String hospitalId;

  const HospitalDetailScreen({super.key, required this.hospitalId});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalsProvider>().loadHospital(widget.hospitalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HospitalsProvider>();
    final hospital = provider.selectedHospital;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hospital == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Établissement introuvable',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ),
      );
    }

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
                Expanded(
                  child: Text(
                    hospital.name,
                    style: PharmaConnectTypography.heading2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hospital.typeName != null)
                  Text(
                    hospital.typeName!,
                    style: PharmaConnectTypography.label,
                  ),
                const Spacer(),
                if (hospital.isEmergencyAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentRed.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: PharmaConnectColors.accentRed.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emergency,
                          size: 14,
                          color: PharmaConnectColors.accentRed,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Urgences',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Adresse', hospital.address),
                          if (hospital.city != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Ville', hospital.city!),
                          ],
                          if (hospital.country != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Pays', hospital.country!),
                          ],
                          if (hospital.phone != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Téléphone', hospital.phone!),
                          ],
                          if (hospital.email != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Email', hospital.email!),
                          ],
                          if (hospital.emergencyPhone != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Urgences', hospital.emergencyPhone!),
                          ],
                          if (hospital.website != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow('Site web', hospital.website!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Services
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Services disponibles',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (hospital.isEmergencyAvailable)
                                _buildServiceChip(
                                  'Urgences',
                                  PharmaConnectColors.accentRed,
                                ),
                              if (hospital.isLabAvailable)
                                _buildServiceChip(
                                  'Laboratoire',
                                  PharmaConnectColors.accentPurple,
                                ),
                              if (hospital.isImagingAvailable)
                                _buildServiceChip(
                                  'Imagerie',
                                  PharmaConnectColors.accentCyan,
                                ),
                              if (hospital.isPharmacyAvailable)
                                _buildServiceChip(
                                  'Pharmacie',
                                  PharmaConnectColors.accentGreen,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // License & Accreditation
                    if (hospital.licenseNumber != null ||
                        hospital.accreditation != null) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accréditations',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            if (hospital.licenseNumber != null) ...[
                              _buildInfoRow('Licence', hospital.licenseNumber!),
                              if (hospital.licenseIssuingBody != null)
                                _buildInfoRow(
                                  'Délivrée par',
                                  hospital.licenseIssuingBody!,
                                ),
                              if (hospital.licenseExpiryDate != null)
                                _buildInfoRow(
                                  'Expiration',
                                  _formatDate(hospital.licenseExpiryDate!),
                                ),
                            ],
                            if (hospital.accreditation != null) ...[
                              if (hospital.licenseNumber != null)
                                const Divider(color: Colors.white12),
                              _buildInfoRow(
                                'Accréditation',
                                hospital.accreditation!,
                              ),
                              if (hospital.accreditationExpiryDate != null)
                                _buildInfoRow(
                                  'Expiration',
                                  _formatDate(
                                    hospital.accreditationExpiryDate!,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (hospital.description != null) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hospital.description!,
                              style: PharmaConnectTypography.body2,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    // Audit Module 23 (HOP), Étape 3 (30/08/2026), HOP-3 :
                    // `widget.isSelectMode` référençait un champ jamais
                    // déclaré sur `HospitalDetailScreen` (seul `hospitalId`
                    // existe, voir le constructeur ci-dessus) — erreur de
                    // compilation certaine, vraisemblable artefact de
                    // copier-coller depuis `HospitalsListScreen`, qui
                    // possède réellement ce champ. Confirmé par recherche
                    // exhaustive que ce widget n'est jamais instancié avec
                    // `isSelectMode` (seule route : `/hospitals/:id`, sans
                    // ce paramètre) — la garde est donc supprimée plutôt que
                    // le champ ajouté : ce bouton doit toujours s'afficher.
                    PrimaryButton(
                      label: 'Prendre RDV dans cet établissement',
                      icon: Icons.calendar_today,
                      onPressed: () {
                        // Navigate to booking with hospital context
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Prise de RDV (à intégrer avec Teleconsult)',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Audit Module 23 (HOP), Étape 3 (30/08/2026), HOP-2 :
                    // rend enfin atteignable HospitalWaitTimesScreen, jusque
                    // là orphelin de toute route et de tout point d'entrée
                    // UI (voir hospital_wait_times_screen.dart et
                    // app_router.dart).
                    PrimaryButton(
                      label: 'Voir les temps d\'attente',
                      icon: Icons.hourglass_bottom,
                      onPressed: () =>
                          context.push('/hospitals/${hospital.id}/wait-times'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

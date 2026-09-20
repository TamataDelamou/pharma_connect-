import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../providers/professionals_provider.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  final String professionalId;

  const ProfessionalDetailScreen({super.key, required this.professionalId});

  @override
  State<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfessionalsProvider>().loadProfessional(
        widget.professionalId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfessionalsProvider>();
    final professional = provider.selectedProfessional;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (professional == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Professionnel introuvable',
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
                const Expanded(
                  child: Text(
                    'Profil professionnel',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (professional.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentGreen.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: PharmaConnectColors.accentGreen.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: PharmaConnectColors.accentGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Vérifié',
                          style: TextStyle(
                            fontSize: 12,
                            color: PharmaConnectColors.accentGreen,
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
                    // Header card
                    GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: PharmaConnectColors.accentCyan
                                .withValues(alpha: 0.1),
                            child: Text(
                              professional.fullName?.substring(0, 1) ?? 'P',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: PharmaConnectColors.accentCyan,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  professional.fullName ?? professional.id,
                                  style: PharmaConnectTypography.heading3,
                                ),
                                Text(
                                  professional.specialty,
                                  style: PharmaConnectTypography.body1,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (professional
                                        .isAcceptingNewPatients) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PharmaConnectColors.accentGreen
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Accepte de nouveaux patients',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                PharmaConnectColors.accentGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (professional.yearsOfExperience != null)
                                      Text(
                                        '${professional.yearsOfExperience} ans d\'expérience',
                                        style: PharmaConnectTypography.micro,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 12),
                          if (professional.bio != null) ...[
                            _buildInfoRow('Bio', professional.bio!),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.phone != null) ...[
                            _buildInfoRow('Téléphone', professional.phone!),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.email != null) ...[
                            _buildInfoRow('Email', professional.email!),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.consultationFee != null) ...[
                            _buildInfoRow(
                              'Consultation',
                              CurrencyFormatter.format(
                                professional.consultationFee!,
                              ),
                            ),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.homeVisitFee != null) ...[
                            _buildInfoRow(
                              'Visite à domicile',
                              CurrencyFormatter.format(
                                professional.homeVisitFee!,
                              ),
                            ),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.licenseNumber != null) ...[
                            _buildInfoRow(
                              'N° Licence',
                              professional.licenseNumber!,
                            ),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.licenseExpiryDate != null) ...[
                            _buildInfoRow(
                              'Expiration licence',
                              _formatDate(professional.licenseExpiryDate!),
                            ),
                            const Divider(color: Colors.white12),
                          ],
                          if (professional.languagesSpoken.isNotEmpty) ...[
                            _buildInfoRow(
                              'Langues',
                              professional.languagesSpoken.join(', '),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Membre depuis ${_formatDate(professional.createdAt)}',
                            style: PharmaConnectTypography.micro.copyWith(
                              color: PharmaConnectColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Availability
                    if (provider.availabilitySlots.isNotEmpty) ...[
                      const Text(
                        'Disponibilités',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: provider.availabilitySlots.map((slot) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: slot.isBreak
                                    ? PharmaConnectColors.textSecondary
                                          .withValues(alpha: 0.1)
                                    : PharmaConnectColors.accentCyan.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: slot.isBreak
                                      ? PharmaConnectColors.textSecondary
                                            .withValues(alpha: 0.2)
                                      : PharmaConnectColors.accentCyan
                                            .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slot.isBreak ? '⏸️' : '✅',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${slot.dayLabel} ${slot.timeRange}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: slot.isBreak
                                          ? PharmaConnectColors.textSecondary
                                          : PharmaConnectColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    // Phase 3 (module professionals) : `if (!widget.
                    // isSelectMode)` référençait un champ jamais déclaré sur
                    // ProfessionalDetailScreen (seul site d'instanciation,
                    // `/professionals/:id`, ne le transmet pas) - même motif
                    // que HOP-3 (HospitalDetailScreen), corrigé de la même
                    // façon : garde supprimée plutôt que champ ajouté, le
                    // bloc s'affiche désormais toujours, seul usage réel.
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Prendre RDV',
                            icon: Icons.calendar_today,
                            onPressed: () {
                              // Navigate to booking (teleconsult or homecare)
                              context.push(
                                '/teleconsult/book',
                                extra: {
                                  'professionalId': professional.id,
                                  'professionalName': professional.fullName,
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Could launch phone call
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Appel téléphonique (à implémenter)',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Contacter'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_role.dart';
import '../providers/marketing_authorization_provider.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4.
class MarketingAuthorizationDetailScreen extends StatefulWidget {
  final String authorizationId;

  const MarketingAuthorizationDetailScreen({
    super.key,
    required this.authorizationId,
  });

  @override
  State<MarketingAuthorizationDetailScreen> createState() =>
      _MarketingAuthorizationDetailScreenState();
}

class _MarketingAuthorizationDetailScreenState
    extends State<MarketingAuthorizationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingAuthorizationProvider>().loadAuthorization(
        widget.authorizationId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketingAuthorizationProvider>();
    final authorization = provider.selectedAuthorization;
    final auth = context.watch<AuthProvider>();
    final canManage =
        auth.isGsgAdmin || auth.effectiveRole == UserRole.regulateur;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authorization == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'AMM introuvable',
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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
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
                      'Détail de l\'AMM',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
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
                          _buildInfoRow(
                            'Médicament',
                            authorization.productName,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Fabricant',
                            authorization.manufacturer,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Numéro d\'AMM',
                            authorization.authorizationNumber,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow(
                            'Organisme émetteur',
                            authorization.issuingBody,
                          ),
                          const Divider(color: Colors.white12),
                          _buildInfoRow('Statut', authorization.statusLabel),
                          if (authorization.expiryDate != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Date d\'expiration',
                              _formatDate(authorization.expiryDate!),
                            ),
                          ],
                          if (authorization.indications != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Indications',
                              authorization.indications!,
                            ),
                          ],
                          if (authorization.contraindications != null) ...[
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              'Contre-indications',
                              authorization.contraindications!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (canManage) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mettre à jour le statut',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (authorization.status == 'pending') ...[
                                  _buildActionChip(
                                    'Approuver',
                                    'approved',
                                    PharmaConnectColors.accentGreen,
                                  ),
                                ],
                                if (authorization.status == 'approved') ...[
                                  _buildActionChip(
                                    'Suspendre',
                                    'suspended',
                                    PharmaConnectColors.accentAmber,
                                  ),
                                  _buildActionChip(
                                    'Révoquer',
                                    'revoked',
                                    PharmaConnectColors.accentRed,
                                  ),
                                ],
                                if (authorization.status == 'suspended') ...[
                                  _buildActionChip(
                                    'Réactiver',
                                    'approved',
                                    PharmaConnectColors.accentGreen,
                                  ),
                                  _buildActionChip(
                                    'Révoquer',
                                    'revoked',
                                    PharmaConnectColors.accentRed,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
            width: 160,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String status, Color color) {
    return GestureDetector(
      onTap: () async {
        final current = context
            .read<MarketingAuthorizationProvider>()
            .selectedAuthorization;
        if (current != null) {
          final updated = current.copyWith(
            status: status,
            approvedAt: status == 'approved' ? DateTime.now().toUtc() : null,
          );
          final success = await context
              .read<MarketingAuthorizationProvider>()
              .saveAuthorization(updated);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Statut mis à jour : $label')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

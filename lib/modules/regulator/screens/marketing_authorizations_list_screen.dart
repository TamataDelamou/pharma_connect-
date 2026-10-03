import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_role.dart';
import '../providers/marketing_authorization_provider.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : écran de liste pour
// `marketing_authorizations` (AMM), jusqu'ici entièrement orpheline. La
// lecture des AMM approuvées reste publique (policy "Public view approved
// authorizations", inchangée depuis l'ouverture du module) ; la gestion
// complète (tous statuts, création) est réservée au staff GSG et aux
// comptes 'regulateur' (RLS posée en Étape 2).
class MarketingAuthorizationsListScreen extends StatefulWidget {
  const MarketingAuthorizationsListScreen({super.key});

  @override
  State<MarketingAuthorizationsListScreen> createState() =>
      _MarketingAuthorizationsListScreenState();
}

class _MarketingAuthorizationsListScreenState
    extends State<MarketingAuthorizationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingAuthorizationProvider>().loadAuthorizations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketingAuthorizationProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage =
        auth.isGsgAdmin || auth.effectiveRole == UserRole.regulateur;

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
                      'Autorisations de mise sur le marché',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (canManage) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/regulator/authorizations/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle AMM'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaConnectColors.accentPurple,
                      foregroundColor: PharmaConnectColors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MarketingAuthorizationProvider provider) {
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
                provider.loadAuthorizations();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.authorizations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucune AMM', style: PharmaConnectTypography.heading3),
            SizedBox(height: 8),
            Text(
              'Aucune autorisation de mise sur le marché enregistrée',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.authorizations.length,
      itemBuilder: (context, index) {
        final authorization = provider.authorizations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () =>
                context.push('/regulator/authorizations/${authorization.id}'),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(authorization.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              authorization.productName,
                              style: PharmaConnectTypography.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                authorization.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              authorization.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(authorization.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${authorization.manufacturer} · ${authorization.authorizationNumber}',
                        style: PharmaConnectTypography.body2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'approved':
        return PharmaConnectColors.accentGreen;
      case 'suspended':
        return PharmaConnectColors.accentAmber;
      case 'revoked':
        return PharmaConnectColors.accentRed;
      case 'expired':
        return PharmaConnectColors.textSecondary;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_role.dart';
import '../providers/marketing_authorization_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
                      'Autorisations de mise sur le marché',
                      style: context.text.heading2,
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
                provider.loadAuthorizations();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.authorizations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucune AMM', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              'Aucune autorisation de mise sur le marché enregistrée',
              style: context.text.body2,
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
                              style: context.text.body1.copyWith(
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
                        style: context.text.body2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
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
        return context.palette.warning;
      case 'approved':
        return context.palette.success;
      case 'suspended':
        return context.palette.warningStrong;
      case 'revoked':
        return context.palette.danger;
      case 'expired':
        return context.palette.textSecondary;
      default:
        return context.palette.textSecondary;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/demand_forecast.dart';
import '../providers/forecast_provider.dart';

/// Écran « Commande recommandée » (cahier, un des 3 écrans principaux du
/// Module 11 — IA). Construit à l'audit Module 11 (29/08/2026), arbitrage
/// D17 : le foundation existait déjà côté `ReorderAlert`/`reorder_alerts`
/// (une fois ses bugs de compilation/RLS/duplication corrigés — voir rapport
/// d'audit), mais aucun écran ne permettait au pharmacien d'éditer une
/// quantité et de valider une proposition avant commande.
///
/// RG-IA-01 (Critique) : « Une commande recommandée par le moteur de
/// prévision ne peut jamais être transmise automatiquement à un fournisseur
/// sans validation explicite du pharmacien. » Respecté par construction :
/// cet écran ne transmet RIEN à un fournisseur — aucune intégration
/// fournisseur n'existe dans le projet (voir arbitrage D18, reporté). La
/// validation ne fait que passer l'alerte en statut 'ordered' côté
/// PharmaConnect, à charge pour le pharmacien de passer la commande
/// réellement par son circuit habituel.
class ReorderRecommendationScreen extends StatefulWidget {
  const ReorderRecommendationScreen({super.key});

  @override
  State<ReorderRecommendationScreen> createState() =>
      _ReorderRecommendationScreenState();
}

class _ReorderRecommendationScreenState
    extends State<ReorderRecommendationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId != null) {
        context.read<StockForecastProvider>().loadPendingReorders(
          pharmacyId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<StockForecastProvider>();

    final isPharmacist = auth.userRole == UserRole.pharmacien;
    final pharmacyId = auth.pharmacyId;

    if (!isPharmacist) {
      return _restrictedScaffold('Réservé aux pharmaciens de l\'officine.');
    }
    if (pharmacyId == null) {
      return _restrictedScaffold(
        'Aucune officine rattachée à ce compte pharmacien.',
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
                    'Commande recommandée',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Propositions de réapprovisionnement — quantité ajustable, '
              'validation obligatoire avant toute commande réelle (RG-IA-01).',
              style: PharmaConnectTypography.body2,
            ),
            if (provider.isOffline) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentOrange.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: PharmaConnectColors.accentOrange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hors ligne — dernières propositions connues '
                        'affichées. Validation/écart indisponibles.',
                        style: TextStyle(
                          fontSize: 12,
                          color: PharmaConnectColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.reorderAlerts.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune proposition de commande en attente.',
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.reorderAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = provider.reorderAlerts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ReorderTile(alert: alert),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _restrictedScaffold(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                message,
                style: PharmaConnectTypography.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderTile extends StatelessWidget {
  final ReorderAlert alert;

  const _ReorderTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.productName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (alert.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentRed.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stock actuel : ${alert.currentStock} · Seuil : ${alert.reorderPoint}',
            style: PharmaConnectTypography.body2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () async {
                  final success = await context
                      .read<StockForecastProvider>()
                      .dismissReorder(alert.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Proposition écartée'
                              : 'Échec de l\'annulation',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Écarter'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _showValidateDialog(context),
                  child: Text(
                    'Valider (${alert.quantityToOrder ?? 0} unités)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showValidateDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: (alert.quantityToOrder ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Valider — ${alert.productName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantité à commander',
            ),
            validator: (value) {
              final n = int.tryParse(value ?? '');
              if (n == null || n <= 0) return 'Nombre entier > 0 requis';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final success = await context.read<StockForecastProvider>().validateReorder(
      alertId: alert.id,
      quantityToOrder: int.parse(controller.text),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Proposition validée pour ${alert.productName} — '
                      'à commander vous-même auprès de votre fournisseur '
                      '(aucune transmission automatique, RG-IA-01)'
                : 'Échec de la validation',
          ),
          backgroundColor: success
              ? PharmaConnectColors.accentGreen
              : PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}

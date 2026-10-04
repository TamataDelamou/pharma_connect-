import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../stock/models/stock_item.dart';
import '../../stock/providers/stock_provider.dart';
import '../../../core/theme/palette.dart';

/// Écran « Paramétrage des seuils par produit » (cahier ALR — audit
/// Module 10, arbitrage D15, 29/08/2026).
///
/// Manquait entièrement avant cet audit : les seuils (`threshold_low`/
/// `threshold_critical`) existaient déjà en base et étaient déjà en écriture
/// pour le staff d'officine (policy `stock_items_write_staff`, Module 4),
/// mais aucun écran ne les exposait autrement qu'en lecture seule
/// (`stock_detail_screen.dart`). Réservé au staff d'officine, même patron de
/// contrôle d'accès que `reconciliation_screen.dart` (Module 8) et
/// `pharmacy_queue_screen.dart` (Module 6).
///
/// Limite assumée (voir rapport d'audit Module 10) : seuils par PRODUIT
/// seulement — un paramétrage par CATÉGORIE, également mentionné au cahier,
/// nécessiterait un champ de seuil au niveau catégorie qui n'existe pas dans
/// le modèle de données actuel (`stock_items` est scopé produit × officine).
/// Non construit ici pour rester dans le périmètre déjà validé avec le
/// porteur du projet.
class AlertThresholdSettingsScreen extends StatefulWidget {
  const AlertThresholdSettingsScreen({super.key});

  @override
  State<AlertThresholdSettingsScreen> createState() =>
      _AlertThresholdSettingsScreenState();
}

class _AlertThresholdSettingsScreenState
    extends State<AlertThresholdSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId != null) {
        context.read<StockProvider>().loadStock(pharmacyId: pharmacyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<StockProvider>();

    final isPharmacist = auth.effectiveRole == UserRole.pharmacien;
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
                      'Paramétrage des seuils',
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
              'Seuils de stock faible et critique par produit — déclenchent '
              'les alertes du Centre d\'alertes (RG-ALR-01).',
              style: context.text.body2,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.stockItems.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun produit en stock pour cette officine.',
                        style: context.text.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.stockItems.length,
                      itemBuilder: (context, index) {
                        final item = provider.stockItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ThresholdTile(item: item),
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
              Icon(
                Icons.lock_outline,
                size: 48,
                color: context.palette.veil(0.24),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: context.text.body2,
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

class _ThresholdTile extends StatelessWidget {
  final StockItem item;

  const _ThresholdTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock disponible : ${item.availableQuantity} · '
                  'Seuil faible : ${item.thresholdLow} · '
                  'Seuil critique : ${item.thresholdCritical}',
                  style: context.text.body2,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Modifier'),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final lowController = TextEditingController(
      text: item.thresholdLow.toString(),
    );
    final criticalController = TextEditingController(
      text: item.thresholdCritical.toString(),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Seuils — ${item.product.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: lowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil stock faible',
                ),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n < 0) return 'Nombre entier ≥ 0 requis';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: criticalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil stock critique',
                ),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n < 0) return 'Nombre entier ≥ 0 requis';
                  final low = int.tryParse(lowController.text);
                  if (low != null && n > low) {
                    return 'Doit être ≤ au seuil faible';
                  }
                  return null;
                },
              ),
            ],
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final success = await context.read<StockProvider>().updateThresholds(
      stockItemId: item.id,
      thresholdLow: int.parse(lowController.text),
      thresholdCritical: int.parse(criticalController.text),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Seuils mis à jour pour ${item.product.name}'
                : 'Échec de la mise à jour des seuils',
          ),
          backgroundColor: success
              ? context.palette.success
              : context.palette.danger,
        ),
      );
    }
  }
}

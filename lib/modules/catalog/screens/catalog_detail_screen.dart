import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../../../core/theme/palette.dart';

class CatalogDetailScreen extends StatefulWidget {
  final String productId;

  const CatalogDetailScreen({super.key, required this.productId});

  @override
  State<CatalogDetailScreen> createState() => _CatalogDetailScreenState();
}

class _CatalogDetailScreenState extends State<CatalogDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadProductDetail(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final product = provider.selectedProduct;
    // Audit Module 3 (29/08/2026) : le bouton "Gérer le stock" menait vers
    // /stock/adjust/:id pour n'importe quel rôle authentifié, y compris un
    // patient — la RLS (is_pharmacy_staff, Module 0) bloque bien l'écriture
    // réelle, mais affichait un bouton menant systématiquement à une
    // impasse pour tout rôle non pertinent. Restreint ici côté affichage à
    // 'pharmacien', seul rôle pouvant un jour satisfaire is_pharmacy_staff.
    final isPharmacyRole =
        context.watch<AuthProvider>().effectiveRole == UserRole.pharmacien;

    if (provider.isDetailLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.detailError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.detailError!,
                textAlign: TextAlign.center,
                style: context.text.body2.copyWith(
                  color: context.palette.danger,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  provider.clearDetailError();
                  provider.loadProductDetail(widget.productId);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (product == null) {
      return const Scaffold(body: Center(child: Text('Produit introuvable')));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                      'Détail du produit',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: context.palette.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.medication,
                                  color: context.palette.primary,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: context.text.heading3,
                                    ),
                                    Text(
                                      product.genericName,
                                      style: context.text.body2,
                                    ),
                                    Text(
                                      '${product.dosage} • ${product.form}',
                                      style: context.text.micro,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: context.palette.veil(0.12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoChip(
                                product.manufacturer,
                                Icons.business,
                                context.palette.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                product.isGeneric ? 'Générique' : 'Princeps',
                                Icons.local_pharmacy,
                                product.isGeneric
                                    ? context.palette.secondary
                                    : context.palette.primary,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                product.isPrescriptionRequired
                                    ? 'Sur ordonnance'
                                    : 'Libre',
                                Icons.description,
                                product.isPrescriptionRequired
                                    ? context.palette.warning
                                    : context.palette.success,
                              ),
                              if (product.isControlledSubstance) ...[
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  'Stupéfiant/Psychotrope',
                                  Icons.warning_amber_rounded,
                                  context.palette.danger,
                                ),
                              ],
                            ],
                          ),
                          if (product.description != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              product.description!,
                              style: context.text.body2,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // ========== BOUTONS D'ACTION ==========
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Vérifier la disponibilité',
                                  icon: Icons.search,
                                  onPressed: () {
                                    context.push('/product/${product.id}');
                                  },
                                ),
                              ),
                              if (isPharmacyRole) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      context.push(
                                        '/stock/adjust/${product.id}',
                                        extra: product.name,
                                      );
                                    },
                                    icon: const Icon(Icons.inventory),
                                    label: const Text('Gérer le stock'),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: context.palette.veil(0.24),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          PharmaConnectSpacing.radiusMd,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

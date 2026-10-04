import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../models/marketing_authorization.dart';
import '../providers/marketing_authorization_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4.
//
// Limitation connue (même motif que pour la création d'inspection) :
// aucun sélecteur de produit catalogue n'existe côté régulateur pour lier
// `product_id` ; le nom du médicament et le fabricant sont saisis
// librement, `product_id` reste optionnel (non-régression : la table
// l'autorise en NULL).
class MarketingAuthorizationCreateScreen extends StatefulWidget {
  const MarketingAuthorizationCreateScreen({super.key});

  @override
  State<MarketingAuthorizationCreateScreen> createState() =>
      _MarketingAuthorizationCreateScreenState();
}

class _MarketingAuthorizationCreateScreenState
    extends State<MarketingAuthorizationCreateScreen> {
  final _productNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _authorizationNumberController = TextEditingController();
  final _issuingBodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _manufacturerController.dispose();
    _authorizationNumberController.dispose();
    _issuingBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Nouvelle AMM',
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassInput(
                            label: 'Médicament',
                            hint: 'Nom du médicament',
                            controller: _productNameController,
                            prefixIcon: Icons.medication,
                          ),
                          const SizedBox(height: 12),
                          GlassInput(
                            label: 'Fabricant',
                            hint: 'Nom du fabricant',
                            controller: _manufacturerController,
                            prefixIcon: Icons.factory_outlined,
                          ),
                          const SizedBox(height: 12),
                          GlassInput(
                            label: 'Numéro d\'AMM',
                            hint: 'Ex : AMM-2026-00123',
                            controller: _authorizationNumberController,
                            prefixIcon: Icons.numbers,
                          ),
                          const SizedBox(height: 12),
                          GlassInput(
                            label: 'Organisme émetteur',
                            hint: 'Ex : DNPM',
                            controller: _issuingBodyController,
                            prefixIcon: Icons.account_balance,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isLoading ? 'Envoi...' : 'Créer',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    TertiaryButton(
                      label: 'Annuler',
                      onPressed: () => context.pop(),
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

  Future<void> _submit() async {
    if (_productNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer le médicament')),
      );
      return;
    }
    if (_manufacturerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer le fabricant')),
      );
      return;
    }
    if (_authorizationNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer le numéro d\'AMM')),
      );
      return;
    }
    if (_issuingBodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer l\'organisme émetteur'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now().toUtc();
    final authorization = MarketingAuthorization(
      id: 'temp_${now.millisecondsSinceEpoch}',
      productName: _productNameController.text.trim(),
      manufacturer: _manufacturerController.text.trim(),
      authorizationNumber: _authorizationNumberController.text.trim(),
      issuingBody: _issuingBodyController.text.trim(),
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    final success = await context
        .read<MarketingAuthorizationProvider>()
        .saveAuthorization(authorization);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AMM créée'),
          backgroundColor: context.palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<MarketingAuthorizationProvider>().error ??
                'Erreur lors de l\'envoi',
          ),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }
}

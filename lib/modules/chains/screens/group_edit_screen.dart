import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../providers/chain_provider.dart';
import '../models/pharmacy_group.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class GroupEditScreen extends StatefulWidget {
  final String groupId;

  const GroupEditScreen({super.key, required this.groupId});

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isDeleting = false;
  // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-8 : la bascule
  // actif/inactif ci-dessous avait un callback vide (`// Handle status
  // change`) — visuellement interactive mais sans aucun effet.
  // `_isActive`/`_isActiveInitialized` portent désormais l'état réel,
  // synchronisé une seule fois depuis `didChangeDependencies` (comme les
  // contrôleurs de texte ci-dessous) puis modifiable localement.
  bool _isActive = true;
  bool _isActiveInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChainProvider>();
      provider.loadGroup(widget.groupId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context.watch<ChainProvider>().selectedGroup;
    if (group != null) {
      _nameController.text = group.name;
      _codeController.text = group.code ?? '';
      _descriptionController.text = group.description ?? '';
      if (!_isActiveInitialized) {
        _isActive = group.isActive;
        _isActiveInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChainProvider>();
    final group = provider.selectedGroup;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (group == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Groupe introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                        'Modifier le groupe',
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
                              label: 'Nom du groupe',
                              hint: 'Ex: PharmaPlus Guinée',
                              controller: _nameController,
                              prefixIcon: Icons.business,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Code (optionnel)',
                              hint: 'Ex: PPG',
                              controller: _codeController,
                              prefixIcon: Icons.code,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Description (optionnel)',
                              hint: 'Description du groupe',
                              controller: _descriptionController,
                              prefixIcon: Icons.description,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),

                            // Status toggle
                            Row(
                              children: [
                                Text('Groupe actif', style: context.text.label),
                                const SizedBox(width: 12),
                                Switch(
                                  value: _isActive,
                                  onChanged: (value) =>
                                      setState(() => _isActive = value),
                                  activeColor: context.palette.success,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: _isLoading
                                  ? 'Enregistrement...'
                                  : 'Enregistrer',
                              isLoading: _isLoading,
                              onPressed: _saveGroup,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isDeleting ? null : _confirmDelete,
                              icon: _isDeleting
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              context.palette.danger,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                              label: const Text('Supprimer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.palette.danger,
                                side: BorderSide(color: context.palette.danger),
                              ),
                            ),
                          ),
                        ],
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
      ),
    );
  }

  Future<void> _saveGroup() async {
    final palette = context.palette;
    if (!_formKey.currentState!.validate()) return;

    final currentGroup = context.read<ChainProvider>().selectedGroup;
    if (currentGroup == null) return;

    setState(() => _isLoading = true);

    final updated = currentGroup.copyWith(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().isNotEmpty
          ? _codeController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      isActive: _isActive,
    );

    final success = await context.read<ChainProvider>().saveGroup(updated);
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Groupe mis à jour'),
          backgroundColor: palette.success,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ChainProvider>().error ?? 'Erreur'),
          backgroundColor: palette.danger,
        ),
      );
    }
  }

  void _confirmDelete() {
    final palette = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Supprimer le groupe'),
        content: const Text(
          'Cette action supprimera le groupe et tous ses membres. '
          'Les données des officines ne seront pas affectées. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              final success = await context.read<ChainProvider>().deleteGroup(
                widget.groupId,
              );
              setState(() => _isDeleting = false);
              if (success && context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Groupe supprimé'),
                    backgroundColor: palette.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

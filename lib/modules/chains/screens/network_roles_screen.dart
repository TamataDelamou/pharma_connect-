import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/network_admin_provider.dart';
import '../models/network_admin_role.dart';

// Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-4 : ce fichier
// n'existait pas alors qu'il était importé et utilisé (`NetworkRolesScreen`)
// à la route `/network/roles` de `app_router.dart` — même défaut que CHN-3,
// import situé dans le routeur global. Créé en s'appuyant sur les méthodes
// déjà exposées par `NetworkAdminProvider` (`loadRoles`/`roles`/`saveRole`/
// `deleteRole`), jusqu'ici sans aucun écran consommateur. La création de
// rôle se fait par saisie d'identifiant utilisateur brut, faute de tout
// composant de sélection d'utilisateur réutilisable dans le codebase — même
// limite documentée que `EnrollmentFormScreen`/`EPrescriptionFormScreen`
// (ASR-3/PRE-5), pas un défaut de sécurité.
class NetworkRolesScreen extends StatefulWidget {
  const NetworkRolesScreen({super.key});

  @override
  State<NetworkRolesScreen> createState() => _NetworkRolesScreenState();
}

class _NetworkRolesScreenState extends State<NetworkRolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkAdminProvider>().loadRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkAdminProvider>();

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
                      '🌐 Rôles d\'administration réseau',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: _showAssignRoleDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Attribuer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(NetworkAdminProvider provider) {
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
                provider.loadRoles();
              },
              width: 200,
            ),
          ],
        ),
      );
    }
    if (provider.roles.isEmpty) {
      return const Center(
        child: Text(
          'Aucun rôle d\'administration réseau attribué',
          style: PharmaConnectTypography.body2,
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.roles.length,
      itemBuilder: (context, index) {
        final role = provider.roles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.roleLabel,
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Utilisateur : ${role.userId}',
                        style: PharmaConnectTypography.micro,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (role.pharmacyGroupId != null)
                        Text(
                          'Groupe : ${role.pharmacyGroupId}',
                          style: PharmaConnectTypography.micro,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: PharmaConnectColors.accentRed,
                  ),
                  tooltip: 'Révoquer',
                  onPressed: () => _confirmRevoke(role),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRevoke(NetworkAdminRole role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Révoquer ce rôle'),
        content: Text(
          'Révoquer le rôle "${role.roleLabel}" de l\'utilisateur ${role.userId} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<NetworkAdminProvider>().deleteRole(role.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentRed,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog() {
    final userIdController = TextEditingController();
    final groupIdController = TextEditingController();
    String selectedRole = 'network_admin';
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: PharmaConnectColors.primaryDeep,
          title: const Text('Attribuer un rôle réseau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'Identifiant utilisateur (UUID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'super_admin',
                    child: Text('👑 Super Administrateur'),
                  ),
                  DropdownMenuItem(
                    value: 'network_admin',
                    child: Text('🌐 Administrateur réseau'),
                  ),
                  DropdownMenuItem(
                    value: 'pharmacy_manager',
                    child: Text('🏥 Gestionnaire d\'officine'),
                  ),
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text('👁️ Observateur'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => selectedRole = value!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: groupIdController,
                decoration: const InputDecoration(
                  labelText: 'Groupe (UUID, optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(
                  dialogError!,
                  style: const TextStyle(
                    color: PharmaConnectColors.accentRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = userIdController.text.trim();
                if (userId.isEmpty) {
                  setDialogState(
                    () => dialogError = 'Identifiant utilisateur requis',
                  );
                  return;
                }
                final now = DateTime.now().toUtc();
                final role = NetworkAdminRole(
                  id: '',
                  userId: userId,
                  role: selectedRole,
                  pharmacyGroupId: groupIdController.text.trim().isNotEmpty
                      ? groupIdController.text.trim()
                      : null,
                  createdAt: now,
                  updatedAt: now,
                );
                Navigator.pop(ctx);
                if (!mounted) return;
                final success = await context
                    .read<NetworkAdminProvider>()
                    .saveRole(role);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<NetworkAdminProvider>().error ?? 'Erreur',
                      ),
                      backgroundColor: PharmaConnectColors.accentRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmaConnectColors.accentCyan,
                foregroundColor: PharmaConnectColors.textOnAccent,
              ),
              child: const Text('Attribuer'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../providers/admin_provider.dart';
import '../models/admin_role.dart';
import '../../../core/theme/palette.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

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
                      'Gestion des utilisateurs',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                // C232 : écran absent — bouton « Ajouter » (création
                // d'utilisateur, /admin/users/create) masqué.
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gérez les comptes utilisateurs et leurs permissions',
              style: context.text.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.users.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun utilisateur',
                        style: context.text.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.users.length,
                      itemBuilder: (context, index) {
                        final user = provider.users[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: user.isActive
                                  ? context.palette.surface
                                  : context.palette.danger.withValues(
                                      alpha: 0.2,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    user.role == AdminRole.superAdmin
                                    ? context.palette.secondary.withValues(
                                        alpha: 0.2,
                                      )
                                    : context.palette.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                child: Text(
                                  user.fullName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: user.role == AdminRole.superAdmin
                                        ? context.palette.secondary
                                        : context.palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: context.text.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(user.email, style: context.text.body2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user.isVerified
                                                ? PharmaConnectColors
                                                      .accentGreen
                                                      .withValues(alpha: 0.15)
                                                : PharmaConnectColors
                                                      .accentOrange
                                                      .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            user.isVerified
                                                ? '✅ Vérifié'
                                                : '⏳ En attente',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: user.isVerified
                                                  ? PharmaConnectColors
                                                        .accentGreen
                                                  : PharmaConnectColors
                                                        .accentOrange,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user.isActive
                                                ? PharmaConnectColors
                                                      .accentGreen
                                                      .withValues(alpha: 0.15)
                                                : context.palette.danger
                                                      .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            user.isActive ? 'Actif' : 'Inactif',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: user.isActive
                                                  ? PharmaConnectColors
                                                        .accentGreen
                                                  : PharmaConnectColors
                                                        .accentRed,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                user.role ==
                                                    AdminRole.superAdmin
                                                ? PharmaConnectColors
                                                      .accentPurple
                                                      .withValues(alpha: 0.15)
                                                : PharmaConnectColors
                                                      .textSecondary
                                                      .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            user.role.label,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  user.role ==
                                                      AdminRole.superAdmin
                                                  ? PharmaConnectColors
                                                        .accentPurple
                                                  : PharmaConnectColors
                                                        .textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!user.isVerified) ...[
                                IconButton(
                                  icon: Icon(
                                    Icons.verified,
                                    color: context.palette.primary,
                                  ),
                                  onPressed: () async {
                                    await provider.verifyUser(user.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Utilisateur vérifié'),
                                          backgroundColor:
                                              context.palette.success,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                              IconButton(
                                icon: Icon(
                                  user.isActive
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                  color: user.isActive
                                      ? context.palette.warning
                                      : context.palette.success,
                                ),
                                onPressed: () async {
                                  await provider.toggleUserActive(
                                    user.id,
                                    !user.isActive,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          user.isActive
                                              ? 'Utilisateur désactivé'
                                              : 'Utilisateur activé',
                                        ),
                                        backgroundColor: user.isActive
                                            ? context.palette.warning
                                            : context.palette.success,
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: context.palette.textSecondary,
                                ),
                                onPressed: () {
                                  // Navigation vers le détail
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

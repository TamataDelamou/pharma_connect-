import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/dashboard_widget.dart';
import '../providers/dashboard_customization_provider.dart';
import '../widgets/dashboard_widget_picker.dart';

class DashboardEditorScreen extends StatefulWidget {
  const DashboardEditorScreen({super.key});

  @override
  State<DashboardEditorScreen> createState() => _DashboardEditorScreenState();
}

class _DashboardEditorScreenState extends State<DashboardEditorScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Audit Module 28 (BI), Étape 3 (05/09/2026), BI-6/BI-7 : cet écran
      // n'était jusqu'ici jamais routé/enregistré (BI-6) et, même une fois
      // atteignable, n'aurait jamais chargé de tableau de bord réel — seul
      // `loadAvailableWidgets()` était appelé ici, `loadUserDashboards()`
      // (devenu `loadDashboardForCurrentUser()`, désormais scopé
      // officine/réseau/personnel) ne l'était jamais, laissant
      // `selectedDashboard` toujours `null`.
      context.read<DashboardCustomizationProvider>().loadAvailableWidgets();
      context
          .read<DashboardCustomizationProvider>()
          .loadDashboardForCurrentUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dashboard = context
        .watch<DashboardCustomizationProvider>()
        .selectedDashboard;
    if (dashboard != null && _nameController.text.isEmpty) {
      _nameController.text = dashboard.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardCustomizationProvider>();

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
                      '📊 Personnaliser le tableau de bord',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (provider.isEditing)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final dashboard = provider.selectedDashboard;
                          if (dashboard != null) {
                            final updated = dashboard.copyWith(
                              name: _nameController.text.trim(),
                            );
                            provider.saveDashboard(updated);
                          }
                          provider.toggleEditing();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tableau de bord enregistré'),
                              backgroundColor: PharmaConnectColors.accentGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmaConnectColors.accentGreen,
                          foregroundColor: PharmaConnectColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          provider.toggleEditing();
                          _nameController.text =
                              provider.selectedDashboard?.name ?? '';
                        },
                        child: const Text('Annuler'),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => provider.toggleEditing(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Personnaliser'),
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
            const SizedBox(height: 8),

            // Dashboard name + portée (BI-7 : officine/réseau/personnel)
            if (provider.isEditing)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du tableau de bord',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Row(
                children: [
                  Text(
                    provider.selectedDashboard?.name ?? 'Tableau de bord',
                    style: PharmaConnectTypography.heading3,
                  ),
                  if (provider.selectedDashboard != null) ...[
                    const SizedBox(width: 8),
                    _buildScopeBadge(provider.selectedDashboard!.scope),
                  ],
                ],
              ),

            // BI-7 : le tableau de bord officine/réseau est partagé entre
            // tout le staff concerné (RLS `user_dashboards_officine_staff` /
            // `_reseau_admin`) — le nom du widget picker le rend explicite.
            if (provider.isEditing) ...[
              const SizedBox(height: 12),
              DashboardWidgetPicker(
                onWidgetSelected: (widgetId) => provider.addWidget(widgetId),
              ),
            ],

            const SizedBox(height: 24),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
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
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              provider.loadAvailableWidgets();
                              provider.loadDashboardForCurrentUser();
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : _buildDashboardPreview(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeBadge(String scope) {
    final label = switch (scope) {
      'officine' => 'Officine',
      'reseau' => 'Réseau GSG',
      _ => 'Personnel',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: PharmaConnectTypography.micro.copyWith(
          color: PharmaConnectColors.accentCyan,
        ),
      ),
    );
  }

  Widget _buildDashboardPreview(DashboardCustomizationProvider provider) {
    final dashboard = provider.selectedDashboard;
    if (dashboard == null) {
      return const Center(child: Text('Aucun tableau de bord configuré'));
    }

    if (dashboard.panels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucun widget ajouté', style: PharmaConnectTypography.body2),
            SizedBox(height: 8),
            Text(
              'Ajoutez des widgets depuis la liste de gauche',
              style: PharmaConnectTypography.micro,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: dashboard.panels.length,
      itemBuilder: (context, index) {
        final panel = dashboard.panels[index];
        final widget = provider.availableWidgets.firstWhere(
          (w) => w.id == panel.widgetId,
          orElse: () => DashboardWidget(
            id: 'unknown',
            name: 'Widget inconnu',
            type: 'kpi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.icon ?? '📊',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: PharmaConnectTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (provider.isEditing)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      // BI-7 : callback jusqu'ici vide (commentaire seul,
                      // aucun effet) — supprime réellement le panneau et
                      // persiste le tableau de bord mis à jour.
                      onPressed: () => provider.removePanel(panel.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Widget preview
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Aperçu du widget',
                      style: PharmaConnectTypography.micro.copyWith(
                        color: PharmaConnectColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

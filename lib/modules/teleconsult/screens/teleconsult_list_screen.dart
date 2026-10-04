import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_role.dart';
import '../providers/teleconsult_provider.dart';
import '../models/consultation_status.dart';
import '../widgets/consultation_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class TeleconsultListScreen extends StatefulWidget {
  final bool asProfessional;

  const TeleconsultListScreen({super.key, this.asProfessional = false});

  @override
  State<TeleconsultListScreen> createState() => _TeleconsultListScreenState();
}

class _TeleconsultListScreenState extends State<TeleconsultListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ConsultationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConsultations();
    });
  }

  void _onTabChanged() {
    final index = _tabController.index;
    setState(() {
      switch (index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = ConsultationStatus.pending;
          break;
        case 2:
          _selectedStatus = ConsultationStatus.confirmed;
          break;
      }
    });
    _loadConsultations();
  }

  void _loadConsultations() {
    final userId = SupabaseService().currentUser?.id;
    // Audit Module 15 (2ème refus de clôture, point de contrôle routage) :
    // ne pas déclencher l'appel réseau "vue professionnel" pour un compte
    // qui n'a pas ce rôle — la RLS le renverrait de toute façon vide, mais
    // autant éviter l'appel inutile plutôt que de laisser `build()` seul
    // masquer le résultat derrière l'écran d'accès refusé.
    final authRole = context.read<AuthProvider>().effectiveRole;
    if (widget.asProfessional && authRole != UserRole.professionnel) return;
    if (userId != null) {
      context.read<TeleconsultProvider>().loadConsultations(
        userId: userId,
        asProfessional: widget.asProfessional,
        status: _selectedStatus,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Audit Module 15 (CNS, 29/08/2026), point de contrôle demandé par le
  /// porteur du projet (2ème refus de clôture) : `app_router.dart` déclare
  /// `/teleconsult/professional` comme un `GoRoute` statique construisant
  /// `TeleconsultListScreen(asProfessional: true)` sans jamais vérifier le
  /// rôle réel du compte connecté — rien n'empêchait un compte `patient`
  /// d'atteindre cette route par URL directe ou navigation manuelle et d'y
  /// voir l'interface « vue professionnel » (libellés « vos patients »,
  /// absence du bouton « Prendre RDV »).
  ///
  /// Ceci n'est PAS une fuite de données : la RLS sur `consultations`
  /// (`Professionals can view assigned consultations`, `auth.uid() =
  /// professional_id`) verrouille déjà hermétiquement l'accès aux lignes —
  /// un patient dont l'UID ne correspond à aucun `professional_id` ne
  /// verrait qu'une liste vide même sans ce garde. C'est un défaut de
  /// cohérence d'interface (rôle affiché ≠ rôle réel), corrigé ici plutôt
  /// que dans `app_router.dart` (aucun mécanisme de `redirect` par rôle
  /// n'existe encore dans ce projet ; le garde est donc placé au niveau de
  /// l'écran, comme le fait déjà `dashboard_screen.dart` pour le calcul de
  /// la route de navigation elle-même — voir `_effectiveNavItems`).
  @override
  Widget build(BuildContext context) {
    final authRole = context.watch<AuthProvider>().effectiveRole;

    if (widget.asProfessional && authRole != UserRole.professionnel) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Accès réservé aux professionnels de santé',
                  style: context.text.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette page n\'est pas disponible pour votre profil.',
                  style: context.text.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Retour à mes téléconsultations',
                  onPressed: () => context.go('/teleconsult'),
                  width: 260,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final provider = context.watch<TeleconsultProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Téléconsultations',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Consultez à distance vos patients ou professionnels de santé',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (!widget.asProfessional) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/teleconsult/book'),
                    icon: const Icon(Icons.add),
                    label: const Text('Prendre RDV'),
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

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
                Tab(text: 'Confirmées'),
              ],
              labelColor: context.palette.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: context.palette.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TeleconsultProvider provider) {
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
                _loadConsultations();
              },
              width: 200,
            ),
          ],
        ),
      );
    }

    if (provider.consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucune consultation', style: context.text.heading3),
            SizedBox(height: 8),
            Text(
              widget.asProfessional
                  ? 'Aucun patient n\'a pris de rendez-vous avec vous'
                  : 'Prenez un rendez-vous pour une téléconsultation',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.consultations.length,
      itemBuilder: (context, index) {
        final consultation = provider.consultations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ConsultationCard(
            consultation: consultation,
            onTap: () => context.push('/teleconsult/${consultation.id}'),
          ),
        );
      },
    );
  }
}

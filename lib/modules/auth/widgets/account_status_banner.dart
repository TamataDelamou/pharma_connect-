import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../pharmacy_staff/widgets/pending_invitations_card.dart';
import '../models/account_status.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/palette.dart';

/// C213 / D64 : bandeau d'état du compte en tête du tableau de bord.
/// Tant que le rôle déclaré n'est pas vérifié, le compte utilise
/// l'application comme un patient ; ce bandeau dit pourquoi et ce qui reste
/// à faire. Un pharmacien sans officine y voit les invitations reçues et peut
/// inscrire sa propre officine. Rien n'est affiché pour un compte actif.
class AccountStatusBanner extends StatefulWidget {
  const AccountStatusBanner({super.key});

  @override
  State<AccountStatusBanner> createState() => _AccountStatusBannerState();
}

class _AccountStatusBannerState extends State<AccountStatusBanner> {
  bool _isRefreshing = false;

  Future<void> _refresh(AuthProvider auth) async {
    setState(() => _isRefreshing = true);
    await auth.restoreSession();
    if (mounted) setState(() => _isRefreshing = false);
  }

  static String _roleLabel(String role) {
    for (final value in UserRole.values) {
      if (value.name == role) return value.label.toLowerCase();
    }
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final status = auth.accountStatus;
    if (status == null) return const SizedBox.shrink();

    // Rôle refusé récemment par GSG : le compte est redevenu patient.
    if (status.state == AccountState.patient) {
      if (status.rejectedRole == null) return const SizedBox.shrink();
      return _frame(
        color: context.palette.warning,
        icon: Icons.info_outline,
        title:
            'Votre demande de compte ${_roleLabel(status.rejectedRole!)} '
            'n\'a pas été acceptée',
        message: [
          if (status.rejectionReason != null)
            'Motif : ${status.rejectionReason}.',
          'Votre compte reste un compte patient. Contactez l\'équipe GSG pour '
              'toute question.',
        ].join(' '),
      );
    }

    if (status.roleActive) return const SizedBox.shrink();

    switch (status.state) {
      case AccountState.noPharmacy:
      case AccountState.pharmacyApplicationRejected:
        return _frame(
          color: context.palette.primary,
          icon: Icons.local_pharmacy,
          title: status.state == AccountState.noPharmacy
              ? 'Votre compte pharmacien n\'est rattaché à aucune officine'
              : 'La candidature de « ${status.applicationName ?? 'votre officine'} » '
                    'n\'a pas été acceptée',
          message:
              'En attendant, vous utilisez PharmaConnect comme un patient. '
              'Acceptez l\'invitation de votre titulaire ou inscrivez votre '
              'propre officine.',
          children: [
            const PendingInvitationsCard(),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/license-verification'),
                icon: const Icon(Icons.add_business),
                label: const Text('Inscrire mon officine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: context.palette.onPrimary,
                ),
              ),
            ),
          ],
          auth: auth,
        );
      case AccountState.pharmacyApplicationPending:
        return _frame(
          color: context.palette.warning,
          icon: Icons.hourglass_top,
          title:
              'Candidature de « ${status.applicationName ?? 'votre officine'} » '
              'en cours de vérification',
          message:
              'L\'équipe GSG vérifie votre licence. Les fonctions officine '
              '(stock, caisse, personnel) seront disponibles dès la '
              'validation ; en attendant, vous utilisez PharmaConnect comme '
              'un patient.',
          children: status.pendingInvitations > 0
              ? const <Widget>[PendingInvitationsCard()]
              : const <Widget>[],
          auth: auth,
        );
      case AccountState.pharmacyInactive:
        return _frame(
          color: context.palette.danger,
          icon: Icons.block,
          title:
              'L\'officine « ${status.pharmacyName ?? 'votre officine'} » '
              'n\'est pas active',
          message:
              'Les fonctions officine sont suspendues tant que l\'officine '
              'n\'est pas réactivée par l\'équipe GSG. Votre rattachement est '
              'conservé.',
          auth: auth,
        );
      case AccountState.professionalProfileMissing:
        return _frame(
          color: context.palette.warning,
          icon: Icons.badge,
          title: 'Votre fiche professionnelle n\'est pas encore enregistrée',
          message:
              'Renseignez votre spécialité et votre numéro d\'ordre : '
              'l\'équipe GSG les vérifiera. En attendant, vous utilisez '
              'PharmaConnect comme un patient.',
          // C222 / D66 : le professionnel crée lui-même sa fiche.
          children: [_profileButton('Créer ma fiche professionnelle')],
          auth: auth,
        );
      case AccountState.professionalRejected:
        return _frame(
          color: context.palette.danger,
          icon: Icons.cancel_outlined,
          title: 'La vérification de votre fiche professionnelle a échoué',
          message: [
            if (status.professionalRejectionReason != null)
              'Motif : ${status.professionalRejectionReason}.',
            'Corrigez votre licence : la fiche repartira en vérification. '
                'En attendant, vous utilisez PharmaConnect comme un patient.',
          ].join(' '),
          children: [_profileButton('Corriger ma fiche')],
          auth: auth,
        );
      case AccountState.pendingReview:
      case AccountState.patient:
      case AccountState.verified:
      case AccountState.unknown:
        return _frame(
          color: context.palette.warning,
          icon: Icons.hourglass_top,
          title: 'Compte ${_roleLabel(status.role)} en attente de vérification',
          message:
              'L\'équipe GSG vérifie votre compte. Les fonctions de votre '
              'métier seront disponibles dès la validation ; en attendant, '
              'vous utilisez PharmaConnect comme un patient.',
          auth: auth,
        );
    }
  }

  /// C222 : accès à la fiche professionnelle depuis le bandeau.
  Widget _profileButton(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/professional/my-profile'),
        icon: const Icon(Icons.badge),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.palette.primary,
          foregroundColor: context.palette.onPrimary,
        ),
      ),
    );
  }

  Widget _frame({
    required Color color,
    required IconData icon,
    required String title,
    required String message,
    List<Widget> children = const [],
    AuthProvider? auth,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.subtitle1),
                    const SizedBox(height: 4),
                    Text(message, style: context.text.body2),
                  ],
                ),
              ),
              if (auth != null)
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: _isRefreshing ? null : () => _refresh(auth),
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
            ],
          ),
          if (children.isNotEmpty) ...[const SizedBox(height: 16), ...children],
        ],
      ),
    );
  }
}

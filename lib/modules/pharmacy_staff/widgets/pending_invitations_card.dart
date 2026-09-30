import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/staff_entry.dart';
import '../services/pharmacy_staff_service.dart';

/// C209 / D59 : invitations reçues par un pharmacien non rattaché. Affiché en
/// tête de l'écran de vérification de licence : un employé d'une officine
/// déjà inscrite accepte ici l'invitation de son titulaire au lieu d'inscrire
/// une nouvelle officine.
class PendingInvitationsCard extends StatefulWidget {
  const PendingInvitationsCard({super.key});

  @override
  State<PendingInvitationsCard> createState() => _PendingInvitationsCardState();
}

class _PendingInvitationsCardState extends State<PendingInvitationsCard> {
  final PharmacyStaffService _service = PharmacyStaffService();

  List<StaffInvitation> _invitations = [];
  bool _isLoading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invitations = await _service.myInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = invitations;
        _isLoading = false;
      });
    } catch (_) {
      // Best-effort : sans réseau, l'écran d'inscription reste utilisable.
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(StaffInvitation invitation, bool accept) async {
    setState(() => _busyId = invitation.invitationId);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    try {
      await _service.respond(invitation.invitationId, accept: accept);
      if (accept) {
        // Relit le profil : pharmacyId est désormais renseigné.
        await auth.restoreSession();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Vous faites partie du personnel de '
                '${invitation.pharmacyName}'),
            backgroundColor: PharmaConnectColors.accentGreen,
          ),
        );
        router.go('/dashboard');
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Invitation refusée')),
      );
      await _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(PharmacyStaffService.describeError(e)),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_invitations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          'Vous travaillez dans une officine déjà inscrite ? Demandez à son '
          'titulaire de vous inviter avec votre numéro de téléphone : '
          'l\'invitation apparaîtra ici.',
          style: PharmaConnectTypography.micro,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invitation à rejoindre une officine',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          for (final invitation in _invitations) _buildInvitation(invitation),
          const SizedBox(height: 8),
          const Text(
            'Pour inscrire votre propre officine, remplissez plutôt le '
            'formulaire ci-dessous.',
            style: PharmaConnectTypography.micro,
          ),
        ],
      ),
    );
  }

  Widget _buildInvitation(StaffInvitation invitation) {
    final busy = _busyId == invitation.invitationId;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PharmaConnectColors.accentCyan.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invitation.pharmacyName,
            style: PharmaConnectTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (invitation.pharmacyAddress != null)
            Text(
              invitation.pharmacyAddress!,
              style: PharmaConnectTypography.micro,
            ),
          if (invitation.invitedByName != null)
            Text(
              'Invitation de ${invitation.invitedByName}',
              style: PharmaConnectTypography.micro,
            ),
          const SizedBox(height: 8),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _busyId == null
                      ? () => _respond(invitation, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentGreen,
                    foregroundColor: PharmaConnectColors.textPrimary,
                  ),
                  child: const Text('Accepter'),
                ),
                TextButton(
                  onPressed: _busyId == null
                      ? () => _respond(invitation, false)
                      : null,
                  child: const Text('Refuser'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

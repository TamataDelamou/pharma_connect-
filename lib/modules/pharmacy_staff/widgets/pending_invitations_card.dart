import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/staff_entry.dart';
import '../services/pharmacy_staff_service.dart';
import '../../../core/theme/palette.dart';

/// C209 / D59 : invitations reçues par un pharmacien non rattaché. Affiché en
/// tête de l'écran de vérification de licence et, depuis C213, dans le
/// bandeau d'état du compte : un employé d'une officine déjà inscrite accepte
/// ici l'invitation de son titulaire au lieu d'inscrire une nouvelle officine.
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
            content: Text(
              'Vous faites partie du personnel de '
              '${invitation.pharmacyName}',
            ),
            backgroundColor: context.palette.success,
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
          backgroundColor: context.palette.danger,
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
      return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          'Vous travaillez dans une officine déjà inscrite ? Demandez à son '
          'titulaire de vous inviter avec votre numéro de téléphone : '
          'l\'invitation apparaîtra ici.',
          style: context.text.micro,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitation à rejoindre une officine',
            style: context.text.heading3,
          ),
          const SizedBox(height: 8),
          for (final invitation in _invitations) _buildInvitation(invitation),
          const SizedBox(height: 8),
          // C213 : la carte est aussi affichée dans le bandeau d'état du
          // compte (tableau de bord), sans formulaire en dessous.
          Text(
            'Pour inscrire votre propre officine, utilisez plutôt le '
            'formulaire d\'inscription d\'officine.',
            style: context.text.micro,
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
        color: context.palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.palette.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invitation.pharmacyName,
            style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          if (invitation.pharmacyAddress != null)
            Text(invitation.pharmacyAddress!, style: context.text.micro),
          if (invitation.invitedByName != null)
            Text(
              'Invitation de ${invitation.invitedByName}',
              style: context.text.micro,
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
                    backgroundColor: context.palette.success,
                    foregroundColor: context.palette.textPrimary,
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

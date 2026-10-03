import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/staff_entry.dart';
import '../services/pharmacy_staff_service.dart';

/// C209 / D59 : personnel de l'officine.
///
/// - Titulaire : liste du personnel et des invitations en attente, invitation
///   d'un compte pharmacien par son numéro de téléphone, annulation d'une
///   invitation, retrait d'un employé.
/// - Employé : l'écran lui propose seulement de quitter l'officine (la liste
///   est réservée au titulaire par le serveur).
class PharmacyStaffScreen extends StatefulWidget {
  const PharmacyStaffScreen({super.key});

  @override
  State<PharmacyStaffScreen> createState() => _PharmacyStaffScreenState();
}

class _PharmacyStaffScreenState extends State<PharmacyStaffScreen> {
  final PharmacyStaffService _service = PharmacyStaffService();

  List<StaffEntry> _entries = [];
  bool _isLoading = true;
  bool _isManager = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String? get _pharmacyId => context.read<AuthProvider>().pharmacyId;

  Future<void> _load() async {
    if (!mounted) return;
    final pharmacyId = _pharmacyId;
    if (pharmacyId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await _service.listStaff(pharmacyId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isManager = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (PharmacyStaffService.isAccessDenied(e)) {
          _isManager = false;
        } else {
          _error = PharmacyStaffService.describeError(e);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _run(
    String busyId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyId = busyId);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
      await _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(PharmacyStaffService.describeError(e)),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _invite() async {
    final pharmacyId = _pharmacyId;
    if (pharmacyId == null) return;
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => const _InviteDialog(),
    );
    if (phone == null || !mounted) return;
    await _run(
      'invite',
      () => _service.invite(pharmacyId, phone),
      'Invitation envoyée : elle apparaîtra à la prochaine connexion de '
          'l\'employé.',
    );
  }

  Future<void> _cancel(StaffEntry entry) async {
    final confirmed = await _confirm(
      title: 'Annuler l\'invitation',
      message:
          'L\'invitation de ${entry.displayName} ne pourra plus être '
          'acceptée.',
      actionLabel: 'Annuler l\'invitation',
    );
    if (!confirmed || !mounted) return;
    await _run(
      entry.invitationId!,
      () => _service.cancelInvitation(entry.invitationId!),
      'Invitation annulée',
    );
  }

  Future<void> _remove(StaffEntry entry) async {
    final pharmacyId = _pharmacyId;
    if (pharmacyId == null) return;
    final confirmed = await _confirm(
      title: 'Retirer du personnel',
      message:
          '${entry.displayName} perdra immédiatement l\'accès au stock, '
          'aux ventes et à la caisse de l\'officine.',
      actionLabel: 'Retirer',
    );
    if (!confirmed || !mounted) return;
    await _run(
      entry.userId,
      () => _service.removeStaff(pharmacyId, entry.userId),
      '${entry.displayName} a été retiré du personnel',
    );
  }

  Future<void> _leave() async {
    final confirmed = await _confirm(
      title: 'Quitter l\'officine',
      message:
          'Vous perdrez l\'accès au stock, aux ventes et à la caisse de '
          'cette officine. Seul son titulaire pourra vous inviter à nouveau.',
      actionLabel: 'Quitter',
    );
    if (!confirmed || !mounted) return;
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    await _run('leave', () async {
      await _service.leave();
      await auth.restoreSession();
      router.go('/dashboard');
    }, 'Vous avez quitté l\'officine');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: Text(title),
        content: Text(message, style: PharmaConnectTypography.body2),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentRed,
              foregroundColor: PharmaConnectColors.textPrimary,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ==================== AFFICHAGE ====================

  @override
  Widget build(BuildContext context) {
    final pharmacyId = context.watch<AuthProvider>().pharmacyId;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        'Personnel de l\'officine',
                        style: PharmaConnectTypography.heading2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: [const KernelBadge()],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: pharmacyId == null
                    ? const Center(
                        child: Text(
                          'Aucune officine rattachée à ce compte.',
                          style: PharmaConnectTypography.body2,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (!_isManager) return _buildEmployeeView();

    final members = _entries.where((e) => e.isMember).toList();
    final invitations = _entries.where((e) => e.isPendingInvitation).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const Text(
            'Invitez vos employés avec le numéro de téléphone de leur compte '
            '(inscrit comme pharmacien). Ils sont rattachés dès qu\'ils '
            'acceptent l\'invitation dans l\'application.',
            style: PharmaConnectTypography.body2,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _busyId == null ? _invite : null,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Inviter un employé'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmaConnectColors.accentCyan,
                foregroundColor: PharmaConnectColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Personnel (${members.length})',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          for (final entry in members) _buildMemberTile(entry),
          const SizedBox(height: 20),
          Text(
            'Invitations en attente (${invitations.length})',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          if (invitations.isEmpty)
            const Text(
              'Aucune invitation en attente.',
              style: PharmaConnectTypography.body2,
            ),
          for (final entry in invitations) _buildInvitationTile(entry),
        ],
      ),
    );
  }

  Widget _buildEmployeeView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'La gestion du personnel est réservée au titulaire de l\'officine.',
            style: PharmaConnectTypography.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_busyId == 'leave')
            const CircularProgressIndicator()
          else
            OutlinedButton.icon(
              onPressed: _leave,
              icon: const Icon(Icons.logout),
              label: const Text('Quitter l\'officine'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PharmaConnectColors.accentRed,
                side: const BorderSide(color: PharmaConnectColors.accentRed),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(StaffEntry entry) {
    return _tile(
      icon: entry.isManager ? Icons.verified : Icons.person,
      iconColor: entry.isManager
          ? PharmaConnectColors.accentGreen
          : PharmaConnectColors.accentCyan,
      title: entry.displayName,
      subtitle: [
        if (entry.isManager) 'Titulaire',
        if (entry.phone != null) entry.phone!,
        if (!entry.isManager && entry.since != null)
          'depuis le ${_formatDate(entry.since!)}',
      ].join(' · '),
      trailing: entry.isManager
          ? null
          : _busyId == entry.userId
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () => _remove(entry),
              style: TextButton.styleFrom(
                foregroundColor: PharmaConnectColors.accentRed,
              ),
              child: const Text('Retirer'),
            ),
    );
  }

  Widget _buildInvitationTile(StaffEntry entry) {
    return _tile(
      icon: Icons.mail_outline,
      iconColor: PharmaConnectColors.accentOrange,
      title: entry.displayName,
      subtitle: [
        if (entry.phone != null) entry.phone!,
        if (entry.since != null) 'invité le ${_formatDate(entry.since!)}',
      ].join(' · '),
      trailing: _busyId == entry.invitationId
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () => _cancel(entry),
              child: const Text('Annuler'),
            ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: PharmaConnectTypography.micro),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

/// Saisie du numéro de téléphone du compte à inviter.
class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final TextEditingController _controller = TextEditingController(
    text: '+224 ',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _controller.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 8;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PharmaConnectColors.primaryDeep,
      title: const Text('Inviter un employé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Numéro de téléphone du compte de l\'employé. Il doit s\'être '
            'inscrit comme pharmacien et ne pas être rattaché à une autre '
            'officine.',
            style: PharmaConnectTypography.body2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              hintText: '+224 6XX XX XX XX',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: PharmaConnectColors.accentCyan,
            foregroundColor: PharmaConnectColors.textPrimary,
          ),
          child: const Text('Inviter'),
        ),
      ],
    );
  }
}

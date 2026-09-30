import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/models/user_role.dart';
import '../models/verification_request.dart';
import '../services/admin_service.dart';

/// C214 : vérification des comptes par l'administration GSG (décision D58,
/// rôle déclaré ≠ rôle vérifié).
///
/// - Grossiste, livreur, régulateur : valider ou refuser (motif ; le compte
///   redevient patient), retirer une validation.
/// - Professionnel de santé : vérifier ou rejeter la fiche (motif).
/// - Pharmacien : validé par la validation de son officine (écran
///   Pharmacies) ; affiché ici pour information.
/// - Recherche : inclut les patients, pour attribuer un rôle institutionnel
///   (un régulateur ne s'inscrit pas lui-même).
///
/// Toutes les règles sont appliquées par le serveur (RPC réservées à
/// is_gsg_admin(), journalisées dans audit_logs).
class RoleVerificationScreen extends StatefulWidget {
  const RoleVerificationScreen({super.key});

  @override
  State<RoleVerificationScreen> createState() => _RoleVerificationScreenState();
}

class _RoleVerificationScreenState extends State<RoleVerificationScreen> {
  static const _states = ['pending', 'verified', 'rejected', 'all'];

  final AdminService _service = AdminService();
  final TextEditingController _searchController = TextEditingController();

  String _state = 'pending';
  List<VerificationRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _service.getVerificationRequests(
        state: _state,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AdminService.describeError(e);
        _isLoading = false;
      });
    }
  }

  void _selectState(String state) {
    if (state == _state) return;
    setState(() => _state = state);
    _load();
  }

  /// Exécute une action d'administration, affiche le résultat, recharge.
  Future<void> _run(
    VerificationRequest request,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyUserId = request.userId);
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
          content: Text(AdminService.describeError(e)),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _approveRole(VerificationRequest r) => _run(
    r,
    () => _service.reviewRole(r.userId, approve: true),
    '${r.displayName} : rôle ${r.role.label} validé',
  );

  Future<void> _rejectRole(VerificationRequest r) async {
    final reason = await _askReason(
      title: 'Refuser le rôle ${r.role.label}',
      help:
          'Le compte redeviendra patient. Le rôle demandé et le motif sont '
          'conservés dans le journal d\'audit.',
      actionLabel: 'Refuser',
    );
    if (reason == null || !mounted) return;
    await _run(
      r,
      () => _service.reviewRole(r.userId, approve: false, reason: reason),
      '${r.displayName} : rôle refusé',
    );
  }

  Future<void> _revokeRole(VerificationRequest r) async {
    final confirmed = await _confirm(
      title: 'Retirer la validation',
      message:
          '${r.displayName} garde le rôle ${r.role.label} déclaré mais perd '
          'les droits associés jusqu\'à une nouvelle validation.',
      actionLabel: 'Retirer',
    );
    if (!confirmed || !mounted) return;
    await _run(
      r,
      () => _service.setUserRole(
        r.userId,
        role: r.declaredRole,
        verified: false,
      ),
      '${r.displayName} : validation retirée',
    );
  }

  Future<void> _verifyProfessional(VerificationRequest r) => _run(
    r,
    () => _service.verifyProfessional(r.userId, approve: true),
    '${r.displayName} : fiche professionnelle vérifiée',
  );

  Future<void> _rejectProfessional(VerificationRequest r) async {
    final reason = await _askReason(
      title: r.isVerified ? 'Retirer la vérification' : 'Rejeter la fiche',
      help:
          'Le professionnel perd les droits associés (ordonnances, '
          'téléconsultation…). Le motif est enregistré sur sa fiche.',
      actionLabel: r.isVerified ? 'Retirer' : 'Rejeter',
    );
    if (reason == null || !mounted) return;
    await _run(
      r,
      () => _service.verifyProfessional(
        r.userId,
        approve: false,
        reason: reason,
      ),
      '${r.displayName} : fiche rejetée',
    );
  }

  Future<void> _assignRole(VerificationRequest r) async {
    final choice = await showDialog<({UserRole role, bool verified})>(
      context: context,
      builder: (_) => _AssignRoleDialog(name: r.displayName),
    );
    if (choice == null || !mounted) return;
    await _run(
      r,
      () => _service.setUserRole(
        r.userId,
        role: choice.role.name,
        verified: choice.verified,
      ),
      '${r.displayName} : rôle ${choice.role.label} attribué'
      '${choice.verified ? ' et validé' : ''}',
    );
  }

  // ==================== DIALOGUES ====================

  Future<String?> _askReason({
    required String title,
    required String help,
    required String actionLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          _ReasonDialog(title: title, help: help, actionLabel: actionLabel),
    );
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentOrange,
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      'Vérification des comptes',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Un rôle déclaré n\'ouvre aucun droit tant qu\'il n\'est pas '
                'vérifié. Les pharmaciens sont validés avec leur officine.',
                style: PharmaConnectTypography.body2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  hintText: 'Rechercher un compte (nom, téléphone, e-mail)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Effacer la recherche',
                    onPressed: () {
                      _searchController.clear();
                      _load();
                    },
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _states.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _StateChip(
                    label: _stateFilterLabel(_states[i]),
                    selected: _state == _states[i],
                    onTap: () => _selectState(_states[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
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
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'Aucun compte dans cette catégorie'
              : 'Aucun compte ne correspond à la recherche',
          style: PharmaConnectTypography.body2,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (_, i) => _buildCard(_requests[i]),
      ),
    );
  }

  Widget _buildCard(VerificationRequest r) {
    final busy = _busyUserId == r.userId;
    final contact = [
      r.phone,
      r.email,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.displayName,
            style: PharmaConnectTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (contact.isNotEmpty)
            Text(contact, style: PharmaConnectTypography.body2),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(
                label: r.role.label,
                color: PharmaConnectColors.accentCyan,
              ),
              _Tag(
                label: _stateLabel(r),
                color: _stateColor(r.verificationState),
              ),
            ],
          ),
          ..._buildDetails(r),
          const SizedBox(height: 8),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Wrap(spacing: 8, runSpacing: 4, children: _buildActions(r)),
        ],
      ),
    );
  }

  List<Widget> _buildDetails(VerificationRequest r) {
    final lines = <String>[];
    if (r.isProfessional) {
      if (r.professionalStatus == null) {
        lines.add('Fiche professionnelle absente : rien à vérifier.');
      } else {
        final licence = [
          if (r.licenseNumber != null) 'Licence ${r.licenseNumber}',
          if (r.licenseIssuingBody != null) r.licenseIssuingBody!,
          if (r.licenseExpiryDate != null)
            'expire le ${_formatDate(r.licenseExpiryDate!)}',
        ].join(' · ');
        lines.add(licence.isEmpty ? 'Aucune licence renseignée' : licence);
        if (r.specialty != null) lines.add('Spécialité : ${r.specialty}');
      }
      if (r.rejectionReason != null) {
        lines.add('Motif du rejet : ${r.rejectionReason}');
      }
    } else if (r.isPharmacist) {
      lines.add(
        r.pharmacyName == null
            ? 'Aucune officine enregistrée'
            : 'Officine : ${r.pharmacyName} (${_pharmacyStatusLabel(r.pharmacyStatus)})',
      );
    } else if (r.isInstitutionalRole && r.roleVerifiedAt != null) {
      lines.add(
        'Validé le ${_formatDate(r.roleVerifiedAt!)}'
        '${r.roleVerifiedByName != null ? ' par ${r.roleVerifiedByName}' : ''}',
      );
    }
    if (r.createdAt != null) {
      lines.add('Inscrit le ${_formatDate(r.createdAt!)}');
    }
    return [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(line, style: PharmaConnectTypography.micro),
        ),
    ];
  }

  List<Widget> _buildActions(VerificationRequest r) {
    if (r.isInstitutionalRole) {
      if (r.isVerified) {
        return [
          _outlined('Retirer la validation', PharmaConnectColors.accentOrange,
              () => _revokeRole(r)),
        ];
      }
      return [
        _filled('Valider', PharmaConnectColors.accentGreen,
            () => _approveRole(r)),
        _outlined('Refuser', PharmaConnectColors.accentRed,
            () => _rejectRole(r)),
      ];
    }
    if (r.isProfessional) {
      if (r.professionalStatus == null) return const [];
      return [
        if (!r.isVerified)
          _filled('Vérifier', PharmaConnectColors.accentGreen,
              () => _verifyProfessional(r)),
        if (!r.isRejected)
          _outlined(
            r.isVerified ? 'Retirer la vérification' : 'Rejeter',
            PharmaConnectColors.accentRed,
            () => _rejectProfessional(r),
          ),
      ];
    }
    if (r.isPharmacist && r.isPending) {
      return [
        TextButton.icon(
          onPressed: () => context.push('/admin/pharmacies?status=pending'),
          icon: const Icon(Icons.local_pharmacy, size: 18),
          label: const Text('Voir les officines en attente'),
        ),
      ];
    }
    if (r.isPatient) {
      return [
        _outlined('Attribuer un rôle', PharmaConnectColors.accentCyan,
            () => _assignRole(r)),
      ];
    }
    return const [];
  }

  Widget _filled(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: PharmaConnectColors.textPrimary,
      ),
      child: Text(label),
    );
  }

  Widget _outlined(String label, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text(label),
    );
  }

  // ==================== LIBELLÉS ====================

  static String _stateFilterLabel(String state) {
    switch (state) {
      case 'pending':
        return 'À valider';
      case 'verified':
        return 'Validés';
      case 'rejected':
        return 'Refusés';
      default:
        return 'Tous';
    }
  }

  static String _stateLabel(VerificationRequest r) {
    switch (r.verificationState) {
      case 'pending':
        return 'À valider';
      case 'verified':
        return r.isProfessional ? 'Vérifié' : 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Sans rôle à vérifier';
    }
  }

  static Color _stateColor(String state) {
    switch (state) {
      case 'pending':
        return PharmaConnectColors.accentOrange;
      case 'verified':
        return PharmaConnectColors.accentGreen;
      case 'rejected':
        return PharmaConnectColors.accentRed;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }

  static String _pharmacyStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'en attente de validation';
      case 'verified':
        return 'vérifiée';
      case 'active':
        return 'active';
      default:
        return status ?? 'statut inconnu';
    }
  }

  static String _formatDate(DateTime date) {
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

/// Attribution d'un rôle institutionnel à un compte patient existant.
class _AssignRoleDialog extends StatefulWidget {
  final String name;

  const _AssignRoleDialog({required this.name});

  @override
  State<_AssignRoleDialog> createState() => _AssignRoleDialogState();
}

class _AssignRoleDialogState extends State<_AssignRoleDialog> {
  static const _roles = [
    UserRole.regulateur,
    UserRole.grossiste,
    UserRole.livreur,
  ];

  UserRole? _role;
  bool _verified = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PharmaConnectColors.primaryDeep,
      title: Text('Attribuer un rôle à ${widget.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Les pharmaciens sont rattachés par la validation de leur '
              'officine, et les professionnels par leur fiche : ils ne '
              's\'attribuent pas ici.',
              style: PharmaConnectTypography.micro,
            ),
            const SizedBox(height: 12),
            for (final role in _roles) ...[
              _buildRoleOption(role),
              const SizedBox(height: 8),
            ],
            CheckboxListTile(
              value: _verified,
              onChanged: (value) => setState(() => _verified = value ?? false),
              title: const Text('Valider immédiatement'),
              subtitle: const Text(
                'Sinon, le rôle reste à valider dans la liste.',
                style: PharmaConnectTypography.micro,
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _role == null
              ? null
              : () => Navigator.pop(context, (role: _role!, verified: _verified)),
          style: ElevatedButton.styleFrom(
            backgroundColor: PharmaConnectColors.accentCyan,
            foregroundColor: PharmaConnectColors.textPrimary,
          ),
          child: const Text('Attribuer'),
        ),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role) {
    final selected = _role == role;
    return InkWell(
      onTap: () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? PharmaConnectColors.accentCyan : Colors.white24,
          ),
          color: selected
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? PharmaConnectColors.accentCyan
                  : PharmaConnectColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                role.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motif obligatoire (3 caractères au moins) pour un refus ou un rejet.
class _ReasonDialog extends StatefulWidget {
  final String title;
  final String help;
  final String actionLabel;

  const _ReasonDialog({
    required this.title,
    required this.help,
    required this.actionLabel,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  static const _minReasonLength = 3;

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().length >= _minReasonLength;
    return AlertDialog(
      backgroundColor: PharmaConnectColors.primaryDeep,
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.help, style: PharmaConnectTypography.body2),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Motif (obligatoire)',
                hintText: 'Au moins 3 caractères',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: canSubmit
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: PharmaConnectColors.accentRed,
            foregroundColor: PharmaConnectColors.textPrimary,
          ),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? PharmaConnectColors.accentCyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? PharmaConnectColors.accentCyan
                  : PharmaConnectColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/professionals_service.dart';

/// C222 / D66 : fiche du professionnel de santé connecté. Il la crée ou la
/// corrige lui-même (spécialité, numéro d'ordre, organisme, date
/// d'expiration) ; la fiche part en attente et l'équipe GSG la vérifie
/// (écran de vérification C214). La vérification n'est jamais modifiable ici.
class MyProfessionalProfileScreen extends StatefulWidget {
  const MyProfessionalProfileScreen({super.key});

  @override
  State<MyProfessionalProfileScreen> createState() =>
      _MyProfessionalProfileScreenState();
}

class _MyProfessionalProfileScreenState
    extends State<MyProfessionalProfileScreen> {
  final _service = ProfessionalsService();
  final _formKey = GlobalKey<FormState>();
  final _specialty = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _issuingBody = TextEditingController();
  final _years = TextEditingController();
  final _bio = TextEditingController();
  DateTime? _expiry;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _exists = false;
  String? _status;
  String? _rejectionReason;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _specialty.dispose();
    _licenseNumber.dispose();
    _issuingBody.dispose();
    _years.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row = await _service.getMyProfileRow();
      if (!mounted) return;
      setState(() {
        _exists = row != null;
        if (row != null) {
          _specialty.text = row['specialty'] as String? ?? '';
          _licenseNumber.text = row['license_number'] as String? ?? '';
          _issuingBody.text = row['license_issuing_body'] as String? ?? '';
          _years.text = (row['years_of_experience'] as num?)?.toString() ?? '';
          _bio.text = row['bio'] as String? ?? '';
          final expiry = row['license_expiry_date'] as String?;
          _expiry = expiry == null ? null : DateTime.tryParse(expiry);
          _status = row['verification_status'] as String?;
          _rejectionReason = row['rejection_reason'] as String?;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger votre fiche.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 20)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await _service.saveMyProfile(
        exists: _exists,
        specialty: _specialty.text.trim(),
        licenseNumber: _licenseNumber.text.trim(),
        licenseIssuingBody: _issuingBody.text.trim(),
        licenseExpiryDate: _expiry,
        yearsOfExperience: int.tryParse(_years.text.trim()),
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      );
      await auth.refreshAccountStatus();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Fiche enregistrée. L\'équipe GSG vérifiera votre numéro d\'ordre.',
          ),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
      router.go('/dashboard');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.replaceFirst(RegExp(r'^PROFIL: '), '');
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Enregistrement impossible. Vérifiez votre connexion.';
        _isSaving = false;
      });
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Champ obligatoire' : null;

  String _statusLabel() {
    switch (_status) {
      case 'verified':
        return 'Fiche vérifiée par GSG. Modifier votre licence relancera '
            'une vérification.';
      case 'rejected':
        return 'Fiche refusée${_rejectionReason != null ? ' : $_rejectionReason' : ''}. '
            'Corrigez votre licence pour la soumettre de nouveau.';
      case 'pending':
        return 'Fiche en attente de vérification par l\'équipe GSG.';
      default:
        return 'Renseignez votre fiche : l\'équipe GSG vérifiera votre '
            'numéro d\'ordre avant d\'activer vos fonctions professionnelles.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // C226 : titre « Ma fiche professionnelle » et retour fournis par AppShell
    // (route_titles.dart), plus de barre propre à l'écran.
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 520,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusLabel(),
                            style: PharmaConnectTypography.body2,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _specialty,
                            decoration: const InputDecoration(
                              labelText: 'Spécialité',
                              hintText: 'Ex. : Pédiatrie, Médecine générale',
                              border: OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _licenseNumber,
                            decoration: const InputDecoration(
                              labelText: 'Numéro d\'ordre',
                              border: OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _issuingBody,
                            decoration: const InputDecoration(
                              labelText: 'Organisme de délivrance',
                              hintText: 'Ex. : Ordre national des médecins',
                              border: OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickExpiry,
                            icon: const Icon(Icons.event),
                            label: Text(
                              _expiry == null
                                  ? 'Date d\'expiration de la licence (facultatif)'
                                  : 'Expire le ${_expiry!.day}/${_expiry!.month}/${_expiry!.year}',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _years,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Années d\'expérience (facultatif)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bio,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Présentation (facultatif)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: PharmaConnectTypography.body2.copyWith(
                                color: PharmaConnectColors.accentRed,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PharmaConnectColors.accentCyan,
                                foregroundColor:
                                    PharmaConnectColors.textOnAccent,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _exists
                                          ? 'Enregistrer les modifications'
                                          : 'Envoyer pour vérification',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

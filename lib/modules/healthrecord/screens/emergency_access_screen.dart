import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/emergency_access.dart';
import '../services/emergency_access_service.dart';

/// C219 / D63 : accès d'urgence au dossier de santé.
/// Pour le patient : qui a ouvert son dossier en urgence, quand, pourquoi, et
/// jusqu'à quand ; il peut mettre fin à un accès en cours.
/// Pour le professionnel : les urgences qu'il a déclarées.
class EmergencyAccessScreen extends StatefulWidget {
  const EmergencyAccessScreen({super.key});

  @override
  State<EmergencyAccessScreen> createState() => _EmergencyAccessScreenState();
}

class _EmergencyAccessScreenState extends State<EmergencyAccessScreen> {
  final _service = EmergencyAccessService();
  List<EmergencyAccess> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is EmergencyAccessException
            ? e.message
            : 'Impossible de charger les accès d\'urgence.';
        _isLoading = false;
      });
    }
  }

  Future<void> _end(EmergencyAccess access) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mettre fin à l\'accès ?'),
        content: Text(
          '${access.professionalName ?? 'Le professionnel'} ne pourra plus '
          'consulter le dossier au titre de cette urgence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mettre fin'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.end(access.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Accès d\'urgence terminé.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is EmergencyAccessException
                ? e.message
                : 'Impossible de mettre fin à l\'accès.',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accès d\'urgence',
                        style: PharmaConnectTypography.heading2,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ouvertures du dossier de santé en urgence, '
                        'tracées et limitées à 24 heures',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _load,
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              textAlign: TextAlign.center,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.accentRed,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun accès d\'urgence.',
          style: PharmaConnectTypography.body2,
        ),
      );
    }
    final userId = SupabaseService().currentUser?.id;
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final access = _items[index];
        final isMyRecord = access.patientId == userId;
        final who = isMyRecord
            ? (access.professionalName ?? 'Professionnel de santé')
            : 'Patient : ${access.patientName ?? access.patientId}';
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    access.isActive ? Icons.lock_open : Icons.lock_outline,
                    color: access.isActive
                        ? PharmaConnectColors.accentRed
                        : PharmaConnectColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(who, style: PharmaConnectTypography.subtitle1),
                  ),
                  Text(
                    access.isActive ? 'En cours' : 'Terminé',
                    style: PharmaConnectTypography.label.copyWith(
                      color: access.isActive
                          ? PharmaConnectColors.accentRed
                          : PharmaConnectColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (access.hospitalName != null)
                Text(
                  'Hôpital : ${access.hospitalName}',
                  style: PharmaConnectTypography.body2,
                ),
              Text(
                'Motif : ${access.reason}',
                style: PharmaConnectTypography.body2,
              ),
              Text(
                'Ouvert le ${_formatDate(access.grantedAt)} — '
                '${access.endedAt != null ? 'terminé le ${_formatDate(access.endedAt!)}' : 'échéance le ${_formatDate(access.expiresAt)}'}',
                style: PharmaConnectTypography.micro,
              ),
              if (access.isActive) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _end(access),
                    icon: const Icon(Icons.block),
                    label: const Text('Mettre fin'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PharmaConnectColors.accentRed,
                      side: const BorderSide(
                        color: PharmaConnectColors.accentRed,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

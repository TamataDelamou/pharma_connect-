import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../services/wait_time_service.dart';
import '../models/hospital_wait_time.dart';

// Audit Module 23 (HOP), Étape 3 (30/08/2026), HOP-2 : l'import ci-dessus
// pointait vers `colors.dart.dart` (double extension, fichier inexistant),
// erreur de compilation certaine. Corrigé. Cet écran n'avait par ailleurs
// aucune route déclarée dans app_router.dart — corrigé au même mouvement
// (`/hospitals/:id/wait-times`), et relié depuis HospitalDetailScreen (voir
// hospital_detail_screen.dart, correctif HOP-2/HOP-3).
class HospitalWaitTimesScreen extends StatefulWidget {
  final String hospitalId;

  const HospitalWaitTimesScreen({super.key, required this.hospitalId});

  @override
  State<HospitalWaitTimesScreen> createState() =>
      _HospitalWaitTimesScreenState();
}

class _HospitalWaitTimesScreenState extends State<HospitalWaitTimesScreen> {
  final WaitTimeService _service = WaitTimeService();
  List<HospitalWaitTime> _waitTimes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _waitTimes = await _service.getWaitTimes(widget.hospitalId);
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                      '🕐 Temps d\'attente en temps réel',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: PharmaConnectColors.textSecondary,
                  ),
                  onPressed: _loadData,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mise à jour en temps réel • Dernière mise à jour : ${_lastUpdated()}',
              style: PharmaConnectTypography.micro,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
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
                          Text(_error!),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: _loadData,
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : _waitTimes.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune information de temps d\'attente disponible',
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _waitTimes.length,
                      itemBuilder: (context, index) {
                        final wt = _waitTimes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wt.department,
                                        style: PharmaConnectTypography.body1
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        wt.waitTimeLabel,
                                        style: TextStyle(
                                          color: wt.waitTimeColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: wt.waitTimeColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${wt.patientsInQueue} patient${wt.patientsInQueue > 1 ? 's' : ''} en file',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: wt.waitTimeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  String _lastUpdated() {
    if (_waitTimes.isEmpty) return 'Non disponible';
    final last = _waitTimes.first.lastUpdated;
    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    return 'il y a ${diff.inHours}h';
  }
}

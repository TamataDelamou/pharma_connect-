import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../services/sos_service.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final SOSService _service = SOSService();
  final _client = SupabaseService().client;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseService().currentUser?.id;

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
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🚨 Alerte SOS',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SOS Button
                  GestureDetector(
                    onTap: _isSending
                        ? null
                        : () => _showSOSOptions(context, userId),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                context.palette.danger,
                                Color.lerp(
                                  context.palette.danger,
                                  context.palette.textPrimary,
                                  context.palette.isDark ? 0.0 : 0.15,
                                )!,
                              ],
                              stops: [0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.palette.danger.withValues(
                                  alpha: 0.4 + 0.3 * _pulseController.value,
                                ),
                                blurRadius: 30 + 20 * _pulseController.value,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🆘', style: TextStyle(fontSize: 48)),
                                SizedBox(height: 8),
                                Text(
                                  'APPUYEZ EN CAS D\'URGENCE',
                                  style: TextStyle(
                                    color: context.palette.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'En appuyant, vous enverrez une alerte\nà vos proches.',
                    textAlign: TextAlign.center,
                    style: context.text.body2,
                  ),

                  const SizedBox(height: 16),

                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),

                  const SizedBox(height: 24),

                  // Quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAction(
                        icon: '📍',
                        label: 'Partager position',
                        onTap: () => _sendLocationSOS(context, userId),
                      ),
                      const SizedBox(width: 16),
                      _buildQuickAction(
                        icon: '📞',
                        label: 'Appeler 15',
                        onTap: () => _callEmergency(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.palette.borderSubtle),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(label, style: context.text.micro),
          ],
        ),
      ),
    );
  }

  void _showSOSOptions(BuildContext context, String? userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.medical_services,
                color: context.palette.danger,
              ),
              title: const Text('Urgence médicale'),
              subtitle: const Text('Problème de santé urgent'),
              onTap: () => _sendSOS('medical_emergency', userId),
            ),
            ListTile(
              leading: Icon(Icons.car_crash, color: context.palette.warning),
              title: const Text('Accident'),
              subtitle: const Text('Accident de la route ou autre'),
              onTap: () => _sendSOS('accident', userId),
            ),
            ListTile(
              leading: Icon(
                Icons.warning_amber,
                color: context.palette.warningStrong,
              ),
              title: const Text('Panique'),
              subtitle: const Text('Situation de danger'),
              onTap: () => _sendSOS('panic', userId),
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: context.palette.primary),
              title: const Text('Partager ma position'),
              subtitle: const Text('Envoyer ma localisation'),
              onTap: () => _sendLocationSOS(context, userId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSOS(String type, String? userId) async {
    final palette = context.palette;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isSending = true);
    Navigator.pop(context);

    // Get family members to notify
    final familyLinks = await _client
        .from('family_links')
        .select('family_member_id')
        .eq('patient_id', userId)
        .eq('status', 'active');

    if (familyLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun membre de la famille configuré')),
      );
      setState(() => _isSending = false);
      return;
    }

    try {
      for (final link in familyLinks as List) {
        final memberId = link['family_member_id'] as String;
        await _service.createSOSAlert(
          patientId: userId,
          familyMemberId: memberId,
          alertType: type,
          message: 'Alerte SOS déclenchée',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alerte envoyée à vos proches'),
          backgroundColor: palette.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }

    setState(() => _isSending = false);
  }

  void _sendLocationSOS(BuildContext context, String? userId) {
    if (userId == null) return;
    // Get current location
    // Then send SOS with location
    _sendSOS('location_share', userId);
  }

  void _callEmergency() {
    // Launch phone dialer
    // Use url_launcher to open tel:15
  }
}

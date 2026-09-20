import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import '../services/sos_service.dart';

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
                    '🚨 Alerte SOS',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
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
                            gradient: const RadialGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              stops: [0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(
                                  alpha: 0.4 + 0.3 * _pulseController.value,
                                ),
                                blurRadius: 30 + 20 * _pulseController.value,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🆘', style: TextStyle(fontSize: 48)),
                                SizedBox(height: 8),
                                Text(
                                  'APPUYEZ EN CAS D\'URGENCE',
                                  style: TextStyle(
                                    color: Colors.white,
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
                    style: PharmaConnectTypography.body2,
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
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(label, style: PharmaConnectTypography.micro),
          ],
        ),
      ),
    );
  }

  void _showSOSOptions(BuildContext context, String? userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PharmaConnectColors.primaryDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.medical_services,
                color: PharmaConnectColors.accentRed,
              ),
              title: const Text('Urgence médicale'),
              subtitle: const Text('Problème de santé urgent'),
              onTap: () => _sendSOS('medical_emergency', userId),
            ),
            ListTile(
              leading: const Icon(
                Icons.car_crash,
                color: PharmaConnectColors.accentOrange,
              ),
              title: const Text('Accident'),
              subtitle: const Text('Accident de la route ou autre'),
              onTap: () => _sendSOS('accident', userId),
            ),
            ListTile(
              leading: const Icon(
                Icons.warning_amber,
                color: PharmaConnectColors.accentAmber,
              ),
              title: const Text('Panique'),
              subtitle: const Text('Situation de danger'),
              onTap: () => _sendSOS('panic', userId),
            ),
            ListTile(
              leading: const Icon(
                Icons.location_on,
                color: PharmaConnectColors.accentCyan,
              ),
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
        const SnackBar(
          content: Text('Alerte envoyée à vos proches'),
          backgroundColor: PharmaConnectColors.accentGreen,
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

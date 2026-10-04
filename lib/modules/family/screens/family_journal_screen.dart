import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../models/family_activity.dart';
import '../providers/family_challenge_provider.dart';
import '../widgets/family_activity_tile.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FamilyJournalScreen extends StatefulWidget {
  final String familyLinkId;

  const FamilyJournalScreen({super.key, required this.familyLinkId});

  @override
  State<FamilyJournalScreen> createState() => _FamilyJournalScreenState();
}

class _FamilyJournalScreenState extends State<FamilyJournalScreen> {
  final _noteController = TextEditingController();
  String _selectedActivityType = 'walk';

  final List<Map<String, String>> _activityTypes = const [
    {'value': 'walk', 'label': '🚶 Marche'},
    {'value': 'water', 'label': '💧 Eau'},
    {'value': 'fruits', 'label': '🍎 Fruits'},
    {'value': 'meditation', 'label': '🧘 Méditation'},
    {'value': 'consultation', 'label': '🩺 Consultation'},
    {'value': 'medication', 'label': '💊 Médicament'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyChallengeProvider>().loadActivities(
        widget.familyLinkId,
      );
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyChallengeProvider>();

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
                      '📖 Journal familial',
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

            // Add entry
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedActivityType,
                    dropdownColor: context.palette.background,
                    style: TextStyle(color: context.palette.textPrimary),
                    items: _activityTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null)
                        setState(() => _selectedActivityType = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Partagez une activité...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: 'Partager',
                    onPressed: _addActivity,
                    width: 100,
                    height: 40,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              provider.loadActivities(widget.familyLinkId);
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.activities.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune activité partagée',
                        style: context.text.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.activities.length,
                      itemBuilder: (context, index) {
                        final activity = provider.activities[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: FamilyActivityTile(
                            activity: activity,
                            onDelete: () async {
                              await provider.deleteActivity(activity.id);
                              provider.loadActivities(widget.familyLinkId);
                            },
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

  Future<void> _addActivity() async {
    final palette = context.palette;
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;

    final activity = FamilyActivity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      familyLinkId: widget.familyLinkId,
      patientId: userId,
      activityType: _selectedActivityType,
      note: note,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now().toUtc(),
    );

    final success = await context
        .read<FamilyChallengeProvider>()
        .createActivity(activity);
    if (success && context.mounted) {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activité partagée !'),
          backgroundColor: palette.success,
        ),
      );
      context.read<FamilyChallengeProvider>().loadActivities(
        widget.familyLinkId,
      );
    }
  }
}

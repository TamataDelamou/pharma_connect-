import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/recall_affected_batch.dart';
import '../models/batch_recall_status.dart';

class AffectedBatchTile extends StatefulWidget {
  final RecallAffectedBatch batch;
  final Function(BatchRecallStatus, int?, int?) onUpdate;

  const AffectedBatchTile({
    super.key,
    required this.batch,
    required this.onUpdate,
  });

  @override
  State<AffectedBatchTile> createState() => _AffectedBatchTileState();
}

class _AffectedBatchTileState extends State<AffectedBatchTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: batch.statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: batch.statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName,
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Lot: ${batch.batchNumber}',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: batch.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    batch.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: batch.statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: PharmaConnectColors.textSecondary,
                ),
              ],
            ),
          ),

          // Détails
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total', style: PharmaConnectTypography.label),
                      Text('${batch.totalUnits} unités'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Retournés',
                        style: PharmaConnectTypography.label,
                      ),
                      Text('${batch.unitsReturned} unités'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détruits',
                        style: PharmaConnectTypography.label,
                      ),
                      Text('${batch.unitsDestroyed} unités'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: batch.completionRate,
              color: batch.completionRate > 0.8
                  ? PharmaConnectColors.accentGreen
                  : PharmaConnectColors.accentOrange,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            if (batch.status != BatchRecallStatus.completed &&
                batch.status != BatchRecallStatus.cancelled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showUpdateDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Mettre à jour'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final unitsReturnedController = TextEditingController();
    final unitsDestroyedController = TextEditingController();
    BatchRecallStatus selectedStatus = BatchRecallStatus.inProgress;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Mettre à jour le lot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<BatchRecallStatus>(
              value: selectedStatus,
              dropdownColor: PharmaConnectColors.primaryDeep,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
              ),
              items: BatchRecallStatus.values.map((status) {
                return DropdownMenuItem<BatchRecallStatus>(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedStatus = value;
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitsReturnedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unités retournées',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitsDestroyedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unités détruites',
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
            onPressed: () {
              final returned = int.tryParse(unitsReturnedController.text);
              final destroyed = int.tryParse(unitsDestroyedController.text);
              widget.onUpdate(selectedStatus, returned, destroyed);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}

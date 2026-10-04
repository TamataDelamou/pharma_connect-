import 'package:flutter/material.dart';
import '../models/recall_affected_batch.dart';
import '../models/batch_recall_status.dart';
import '../../../core/theme/palette.dart';

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
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: batch.statusColor.of(context.palette).withValues(alpha: 0.2),
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
                    color: batch.statusColor.of(context.palette),
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
                        style: context.text.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Lot: ${batch.batchNumber}',
                        style: context.text.body2,
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
                    color: batch.statusColor
                        .of(context.palette)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    batch.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: batch.statusColor.of(context.palette),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: context.palette.textSecondary,
                ),
              ],
            ),
          ),

          // Détails
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Divider(color: context.palette.veil(0.12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: context.text.label),
                      Text('${batch.totalUnits} unités'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Retournés', style: context.text.label),
                      Text('${batch.unitsReturned} unités'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Détruits', style: context.text.label),
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
                  ? context.palette.success
                  : context.palette.warning,
              backgroundColor: context.palette.border,
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
                        side: BorderSide(color: context.palette.veil(0.24)),
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
        backgroundColor: context.palette.background,
        title: const Text('Mettre à jour le lot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<BatchRecallStatus>(
              value: selectedStatus,
              dropdownColor: context.palette.background,
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
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}

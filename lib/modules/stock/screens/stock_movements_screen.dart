import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../providers/stock_provider.dart';

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();

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
                    'Historique des mouvements',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.movements.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun mouvement enregistré',
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.movements.length,
                      itemBuilder: (context, index) {
                        final movement = provider.movements[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                movement.quantity > 0
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: movement.typeColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movement.typeLabel,
                                      style: PharmaConnectTypography.body1
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (movement.notes != null) ...[
                                      Text(
                                        movement.notes!,
                                        style: PharmaConnectTypography.body2,
                                      ),
                                    ],
                                    Text(
                                      _formatDate(movement.timestamp),
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${movement.quantity > 0 ? "+" : ""}${movement.quantity}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: movement.quantity > 0
                                      ? PharmaConnectColors.accentGreen
                                      : PharmaConnectColors.accentRed,
                                ),
                              ),
                            ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../providers/stock_provider.dart';
import '../../../core/theme/palette.dart';

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
                      'Historique des mouvements',
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
              child: provider.movements.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun mouvement enregistré',
                        style: context.text.body2,
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
                            color: context.palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Audit Module 4 (29/08/2026) : mêmes icônes
                              // inversées corrigées que dans
                              // stock_detail_screen.dart.
                              Icon(
                                movement.quantity > 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: movement.typeColor.of(context.palette),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movement.typeLabel,
                                      style: context.text.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (movement.notes != null) ...[
                                      Text(
                                        movement.notes!,
                                        style: context.text.body2,
                                      ),
                                    ],
                                    Text(
                                      _formatDate(movement.timestamp),
                                      style: context.text.micro,
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
                                      ? context.palette.success
                                      : context.palette.danger,
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

import 'package:flutter/material.dart';
import '../../../core/pilot/pilot_config.dart';
import '../../../core/theme/spacing.dart';
import '../models/payment_method.dart';
import '../../../core/theme/palette.dart';

class PaymentMethodSelector extends StatefulWidget {
  final List<PaymentMethod> availableMethods;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final bool showCashback;

  const PaymentMethodSelector({
    super.key,
    required this.availableMethods,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showCashback = true,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moyen de paiement', style: context.text.label),
        const SizedBox(height: 8),
        ...widget.availableMethods.map((method) {
          final isSelected = widget.selectedMethod == method;
          final cashback =
              method.isMobileMoney || method == PaymentMethod.gsgWallet;

          return GestureDetector(
            onTap: () => widget.onMethodSelected(method),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.palette.primary.withValues(alpha: 0.1)
                    : context.palette.surfaceMuted,
                borderRadius: BorderRadius.circular(
                  PharmaConnectSpacing.radiusMd,
                ),
                border: Border.all(
                  color: isSelected
                      ? context.palette.primary
                      : context.palette.surface,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(method.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method.label,
                      style: context.text.body1.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  // C239 : pastille masquée pour le pilote (`PilotConfig`).
                  if (PilotConfig.cashback &&
                      widget.showCashback &&
                      cashback) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '2% cashback',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: context.palette.success,
                        ),
                      ),
                    ),
                  ],
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: context.palette.primary),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

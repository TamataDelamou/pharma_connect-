import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/payment_method.dart';

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
        const Text('Moyen de paiement', style: PharmaConnectTypography.label),
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
                    ? PharmaConnectColors.accentCyan.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(
                  PharmaConnectSpacing.radiusMd,
                ),
                border: Border.all(
                  color: isSelected
                      ? PharmaConnectColors.accentCyan
                      : Colors.white.withValues(alpha: 0.06),
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
                      style: PharmaConnectTypography.body1.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (widget.showCashback && cashback) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PharmaConnectColors.accentGreen.withValues(alpha: 
                          0.15,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '2% cashback',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentGreen,
                        ),
                      ),
                    ),
                  ],
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: PharmaConnectColors.accentCyan,
                    ),
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

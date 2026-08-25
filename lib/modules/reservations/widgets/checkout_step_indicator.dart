import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class CheckoutStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const CheckoutStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Row(
            children: [
              // Cercle avec numéro
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? PharmaConnectColors.accentCyan
                      : Colors.white.withValues(alpha: 0.1),
                  border: isCurrent
                      ? Border.all(
                          color: PharmaConnectColors.accentCyan,
                          width: 3,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive
                          ? PharmaConnectColors.textOnAccent
                          : PharmaConnectColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Ligne entre les cercles
              if (index < steps.length - 1) ...[
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentStep
                        ? PharmaConnectColors.accentCyan
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

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
                      ? context.palette.primary
                      : context.palette.border,
                  border: isCurrent
                      ? Border.all(color: context.palette.primary, width: 3)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive
                          ? context.palette.onPrimary
                          : context.palette.textSecondary,
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
                        ? context.palette.primary
                        : context.palette.border,
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

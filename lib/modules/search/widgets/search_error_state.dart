import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';

class SearchErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SearchErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 56,
            color: PharmaConnectColors.accentRed,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: PharmaConnectTypography.body1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Réessayer',
            icon: Icons.refresh,
            width: 200,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

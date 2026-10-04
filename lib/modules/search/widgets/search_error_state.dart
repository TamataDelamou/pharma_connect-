import 'package:flutter/material.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/theme/palette.dart';

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
          Icon(Icons.error_outline, size: 56, color: context.palette.danger),
          const SizedBox(height: 16),
          Text(message, style: context.text.body1, textAlign: TextAlign.center),
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

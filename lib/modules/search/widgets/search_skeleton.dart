import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: context.palette.veil(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

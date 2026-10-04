import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class FamilyAlertBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const FamilyAlertBadge({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: context.palette.textPrimary,
          ),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: context.palette.danger,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

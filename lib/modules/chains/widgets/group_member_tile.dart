import 'package:flutter/material.dart';
import '../models/group_member.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class GroupMemberTile extends StatelessWidget {
  final GroupMember member;

  const GroupMemberTile({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _roleColor(
              context,
              member.role,
            ).withValues(alpha: 0.15),
            child: Text(
              member.pharmacyName?.substring(0, 1) ?? 'P',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _roleColor(context, member.role),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.pharmacyName ?? member.pharmacyId,
                  style: context.text.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (member.pharmacyCity != null)
                  Text(member.pharmacyCity!, style: context.text.micro),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _roleColor(context, member.role).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              member.roleLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _roleColor(context, member.role),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return context.palette.danger;
      case 'manager':
        return context.palette.warning;
      case 'staff':
        return context.palette.primary;
      case 'viewer':
        return context.palette.textSecondary;
      default:
        return context.palette.textSecondary;
    }
  }
}

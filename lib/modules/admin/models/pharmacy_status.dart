enum PharmacyStatus {
  pending,
  verified,
  active,
  suspended,
  underReview,
  rejected,
}

extension PharmacyStatusExtension on PharmacyStatus {
  String get label {
    switch (this) {
      case PharmacyStatus.pending:
        return 'En attente';
      case PharmacyStatus.verified:
        return 'Vérifiée';
      case PharmacyStatus.active:
        return 'Active';
      case PharmacyStatus.suspended:
        return 'Suspendue';
      case PharmacyStatus.underReview:
        return 'En révision';
      case PharmacyStatus.rejected:
        return 'Rejetée';
    }
  }
}

enum FamilyLinkStatus { pending, active, revoked }

extension FamilyLinkStatusExtension on FamilyLinkStatus {
  String get label {
    switch (this) {
      case FamilyLinkStatus.pending:
        return 'En attente';
      case FamilyLinkStatus.active:
        return 'Actif';
      case FamilyLinkStatus.revoked:
        return 'Révoqué';
    }
  }

  String get icon {
    switch (this) {
      case FamilyLinkStatus.pending:
        return '⏳';
      case FamilyLinkStatus.active:
        return '✅';
      case FamilyLinkStatus.revoked:
        return '❌';
    }
  }

  bool get isActive => this == FamilyLinkStatus.active;
  bool get isPending => this == FamilyLinkStatus.pending;
}

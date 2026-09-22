enum HomecareStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  missed,
}

extension HomecareStatusExtension on HomecareStatus {
  String get label {
    switch (this) {
      case HomecareStatus.pending:
        return 'En attente';
      case HomecareStatus.confirmed:
        return 'Confirmée';
      case HomecareStatus.inProgress:
        return 'En cours';
      case HomecareStatus.completed:
        return 'Terminée';
      case HomecareStatus.cancelled:
        return 'Annulée';
      case HomecareStatus.missed:
        return 'Non honorée';
    }
  }

  String get icon {
    switch (this) {
      case HomecareStatus.pending:
        return '⏳';
      case HomecareStatus.confirmed:
        return '✅';
      case HomecareStatus.inProgress:
        return '🔄';
      case HomecareStatus.completed:
        return '📋';
      case HomecareStatus.cancelled:
        return '❌';
      case HomecareStatus.missed:
        return '⚠️';
    }
  }

  bool get isActive =>
      this == HomecareStatus.pending ||
      this == HomecareStatus.confirmed ||
      this == HomecareStatus.inProgress;
  bool get isPast =>
      this == HomecareStatus.completed ||
      this == HomecareStatus.missed ||
      this == HomecareStatus.cancelled;

  // Audit Module 18 (HOM, 30/08/2026) : la contrainte CHECK de
  // `homecare_interventions.status` (migration `20260827004000_homecare.sql`)
  // n'autorise que 'pending'/'confirmed'/'in_progress'/'completed'/
  // 'cancelled'/'missed' — hors énumération Dart `HomecareStatus.inProgress`,
  // dont `.name` retourne littéralement 'inProgress' (camelCase), jamais
  // rencontré par la contrainte SQL en snake_case. Toute tentative de faire
  // passer une intervention en cours (`updateInterventionStatus(...,
  // HomecareStatus.inProgress)`) violait donc systématiquement la contrainte
  // CHECK côté base — un défaut nouveau pour cet audit (dérive
  // sérialisation-énumération vs contrainte SQL, distinct du motif « rôle
  // inatteignable »). `dbValue`/`fromDbValue` remplacent tout usage de
  // `.name` pour la colonne `status` afin de ne plus dépendre d'une
  // coïncidence entre l'identifiant Dart et la valeur SQL.
  String get dbValue =>
      this == HomecareStatus.inProgress ? 'in_progress' : name;
}

HomecareStatus homecareStatusFromDb(String value) => HomecareStatus.values
    .firstWhere((e) => e.dbValue == value, orElse: () => HomecareStatus.pending);

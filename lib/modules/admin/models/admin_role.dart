enum AdminRole {
  superAdmin,
  admin,
  pharmacyManager,
  regulator,
  auditor,
  support,
  viewer,
}

extension AdminRoleExtension on AdminRole {
  String get label {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Administrateur';
      case AdminRole.admin:
        return 'Administrateur';
      case AdminRole.pharmacyManager:
        return 'Gestionnaire de pharmacie';
      case AdminRole.regulator:
        return 'Régulateur';
      case AdminRole.auditor:
        return 'Auditeur';
      case AdminRole.support:
        return 'Support';
      case AdminRole.viewer:
        return 'Consultant';
    }
  }

  String get description {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Accès complet à toutes les fonctionnalités';
      case AdminRole.admin:
        return 'Gestion des utilisateurs et des pharmacies';
      case AdminRole.pharmacyManager:
        return 'Gestion d\'une ou plusieurs pharmacies';
      case AdminRole.regulator:
        return 'Accès aux rapports et données de conformité';
      case AdminRole.auditor:
        return 'Accès en lecture aux logs et audits';
      case AdminRole.support:
        return 'Support client et gestion des tickets';
      case AdminRole.viewer:
        return 'Accès en lecture seule';
    }
  }
}

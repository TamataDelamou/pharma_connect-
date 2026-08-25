enum AdminPermission {
  // Gestion utilisateurs
  userCreate,
  userRead,
  userUpdate,
  userDelete,
  userActivate,
  userDeactivate,

  // Gestion pharmacies
  pharmacyCreate,
  pharmacyRead,
  pharmacyUpdate,
  pharmacyDelete,
  pharmacyApprove,

  // Gestion licences
  licenseView,
  licenseVerify,
  licenseApprove,

  // Gestion rôles
  roleCreate,
  roleUpdate,
  roleDelete,

  // Audit
  auditRead,
  auditExport,

  // Configuration
  configRead,
  configUpdate,

  // Rapports
  reportView,
  reportGenerate,
  reportExport,

  // Support
  supportView,
  supportCreate,
  supportUpdate,

  // Système
  systemView,
  systemUpdate,
}

extension AdminPermissionExtension on AdminPermission {
  String get label {
    switch (this) {
      case AdminPermission.userCreate:
        return 'Créer des utilisateurs';
      case AdminPermission.userRead:
        return 'Voir les utilisateurs';
      case AdminPermission.userUpdate:
        return 'Modifier les utilisateurs';
      case AdminPermission.userDelete:
        return 'Supprimer des utilisateurs';
      case AdminPermission.userActivate:
        return 'Activer des utilisateurs';
      case AdminPermission.userDeactivate:
        return 'Désactiver des utilisateurs';
      case AdminPermission.pharmacyCreate:
        return 'Créer des pharmacies';
      case AdminPermission.pharmacyRead:
        return 'Voir les pharmacies';
      case AdminPermission.pharmacyUpdate:
        return 'Modifier les pharmacies';
      case AdminPermission.pharmacyDelete:
        return 'Supprimer des pharmacies';
      case AdminPermission.pharmacyApprove:
        return 'Approuver des pharmacies';
      case AdminPermission.licenseView:
        return 'Voir les licences';
      case AdminPermission.licenseVerify:
        return 'Vérifier les licences';
      case AdminPermission.licenseApprove:
        return 'Approuver les licences';
      case AdminPermission.roleCreate:
        return 'Créer des rôles';
      case AdminPermission.roleUpdate:
        return 'Modifier des rôles';
      case AdminPermission.roleDelete:
        return 'Supprimer des rôles';
      case AdminPermission.auditRead:
        return 'Voir les audits';
      case AdminPermission.auditExport:
        return 'Exporter les audits';
      case AdminPermission.configRead:
        return 'Voir la configuration';
      case AdminPermission.configUpdate:
        return 'Modifier la configuration';
      case AdminPermission.reportView:
        return 'Voir les rapports';
      case AdminPermission.reportGenerate:
        return 'Générer des rapports';
      case AdminPermission.reportExport:
        return 'Exporter des rapports';
      case AdminPermission.supportView:
        return 'Voir les tickets de support';
      case AdminPermission.supportCreate:
        return 'Créer des tickets';
      case AdminPermission.supportUpdate:
        return 'Modifier des tickets';
      case AdminPermission.systemView:
        return 'Voir les informations système';
      case AdminPermission.systemUpdate:
        return 'Modifier le système';
    }
  }

  String get category {
    switch (this) {
      case AdminPermission.userCreate:
      case AdminPermission.userRead:
      case AdminPermission.userUpdate:
      case AdminPermission.userDelete:
      case AdminPermission.userActivate:
      case AdminPermission.userDeactivate:
        return 'Utilisateurs';
      case AdminPermission.pharmacyCreate:
      case AdminPermission.pharmacyRead:
      case AdminPermission.pharmacyUpdate:
      case AdminPermission.pharmacyDelete:
      case AdminPermission.pharmacyApprove:
        return 'Pharmacies';
      case AdminPermission.licenseView:
      case AdminPermission.licenseVerify:
      case AdminPermission.licenseApprove:
        return 'Licences';
      case AdminPermission.roleCreate:
      case AdminPermission.roleUpdate:
      case AdminPermission.roleDelete:
        return 'Rôles';
      case AdminPermission.auditRead:
      case AdminPermission.auditExport:
        return 'Audit';
      case AdminPermission.configRead:
      case AdminPermission.configUpdate:
        return 'Configuration';
      case AdminPermission.reportView:
      case AdminPermission.reportGenerate:
      case AdminPermission.reportExport:
        return 'Rapports';
      case AdminPermission.supportView:
      case AdminPermission.supportCreate:
      case AdminPermission.supportUpdate:
        return 'Support';
      case AdminPermission.systemView:
      case AdminPermission.systemUpdate:
        return 'Système';
    }
  }
}

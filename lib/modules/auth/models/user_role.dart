enum UserRole {
  patient,
  pharmacien,
  grossiste,
  livreur,
  professionnel,
  regulateur,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.pharmacien:
        return 'Pharmacien titulaire';
      case UserRole.grossiste:
        return 'Grossiste répartiteur';
      case UserRole.livreur:
        return 'Livreur';
      case UserRole.professionnel:
        return 'Professionnel de santé';
      case UserRole.regulateur:
        return 'Régulateur / Institution';
    }
  }
}

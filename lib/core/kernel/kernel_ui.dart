/// Interrupteur central des éléments d'interface qui annoncent le Kernel GSG
/// (badge « Kernel », indicateur de connexion).
///
/// Le Kernel n'est pas branché (registre, D2) : tant que [enabled] est faux,
/// `KernelBadge` et `KernelConnectionIndicator` ne dessinent rien, sur tous
/// les écrans. Les widgets restent en place dans les écrans ; passer
/// [enabled] à vrai les rétablit partout, sans autre changement.
class KernelUi {
  static const bool enabled = false;
}

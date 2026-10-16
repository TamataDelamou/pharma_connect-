import 'package:flutter/material.dart';

import '../core/pilot/pilot_config.dart';
import '../core/widgets/navigation/sidebar_navigation.dart';
import '../modules/auth/models/user_role.dart';

/// C226 : menu unique de l'application, affiché par AppShell (barre latérale
/// en largeur, tiroir sur téléphone). Sorti de dashboard_screen.dart, qui
/// n'affiche plus sa propre barre latérale.
const List<SidebarNavigationItem> appMenuItems = [
  SidebarNavigationItem(
    label: 'Tableau de bord',
    icon: Icons.dashboard,
    route: '/dashboard',
  ),
  SidebarNavigationItem(
    label: 'Recherche',
    icon: Icons.search,
    route: '/search',
  ),
  SidebarNavigationItem(
    label: 'Catalogue',
    icon: Icons.medication_liquid,
    route: '/catalog',
  ),
  SidebarNavigationItem(
    label: 'Stock & Lots',
    icon: Icons.inventory,
    route: '/stock',
  ),
  SidebarNavigationItem(
    label: 'Ordonnances',
    icon: Icons.description,
    route: '/prescriptions',
  ),
  // C245 : le panier de réservation n'avait aucun lien d'accès.
  SidebarNavigationItem(
    label: 'Panier',
    icon: Icons.shopping_basket,
    route: '/cart',
  ),
  // C231 : `/reservations` n'existe pas ; la liste est /reservations/history.
  SidebarNavigationItem(
    label: 'Réservations',
    icon: Icons.shopping_cart,
    route: '/reservations/history',
  ),
  SidebarNavigationItem(
    label: 'Livraisons',
    icon: Icons.local_shipping,
    route: '/deliveries',
  ),
  // C226 : écran de liste trouvé par C232, sans contrôle de rôle comme ses
  // routes sœurs (/healthrecord…).
  SidebarNavigationItem(
    label: 'Objectifs santé',
    icon: Icons.flag,
    route: '/healthrecord/goals',
  ),
  // C231 : « Paramètres » masqué, `/settings` n'existe pas encore (C227).
];

/// C245 : écrans de l'officine, réservés au pharmacien vérifié (titulaire ou
/// personnel rattaché). Sans ces entrées, la file des réservations, la caisse
/// et l'historique des ventes étaient inatteignables sur téléphone.
const List<SidebarNavigationItem> pharmacyMenuItems = [
  SidebarNavigationItem(
    label: 'File des réservations',
    icon: Icons.assignment_turned_in,
    route: '/pharmacy/queue',
  ),
  // C274 : libellé selon l'état de la caisse, voir [cashMenuLabel].
  SidebarNavigationItem(
    label: 'Caisse',
    icon: Icons.point_of_sale,
    route: '/cash',
  ),
  SidebarNavigationItem(
    label: 'Historique des ventes',
    icon: Icons.receipt_long,
    route: '/pos/history',
  ),
];

/// C245 : administration GSG (validation des officines, des rôles et des
/// professionnels), réservée aux comptes inscrits dans `admin_users`.
const SidebarNavigationItem adminMenuItem = SidebarNavigationItem(
  label: 'Administration',
  icon: Icons.admin_panel_settings,
  route: '/admin',
);

/// C274 : libellé de l'entrée de la caisse : « Ouverture de caisse » si la caisse
/// du caissier connecté est fermée, « Fermeture de caisse » si elle est
/// ouverte, « Caisse » tant que l'état n'est pas connu (décision d'Achille
/// du 16/10/2026).
String cashMenuLabel(bool? drawerOpen) => switch (drawerOpen) {
  true => 'Fermeture de caisse',
  false => 'Ouverture de caisse',
  null => 'Caisse',
};

/// C213 / D64 : menus selon le rôle effectif. Un compte dont le rôle n'est
/// pas vérifié (ou un patient) n'a pas le menu « Stock & Lots ».
/// C245 : le pharmacien vérifié a en plus les écrans de l'officine ;
/// l'administrateur GSG a « Administration », quel que soit son rôle.
List<SidebarNavigationItem> appMenuFor(
  UserRole? role, {
  bool isGsgAdmin = false,
  bool? cashDrawerOpen,
}) {
  // C239 : « Livraisons » masqué pendant le pilote (retrait à l'officine
  // seulement).
  // C270 : « Objectifs santé » masqué pendant le pilote.
  bool visible(SidebarNavigationItem item) =>
      (PilotConfig.reservationDelivery || item.route != '/deliveries') &&
      (PilotConfig.healthGoals || item.route != '/healthrecord/goals') &&
      (role != UserRole.patient || item.route != '/stock');
  final items = appMenuItems.where(visible).toList();
  if (role == UserRole.pharmacien) {
    items.addAll([
      for (final item in pharmacyMenuItems)
        item.route == '/cash'
            ? SidebarNavigationItem(
                label: cashMenuLabel(cashDrawerOpen),
                icon: item.icon,
                route: item.route,
              )
            : item,
    ]);
  }
  if (isGsgAdmin) items.add(adminMenuItem);
  return items;
}

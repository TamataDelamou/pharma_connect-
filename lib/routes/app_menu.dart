import 'package:flutter/material.dart';

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

/// C213 / D64 : menus selon le rôle effectif. Un compte dont le rôle n'est
/// pas vérifié (ou un patient) n'a pas le menu « Stock & Lots ».
List<SidebarNavigationItem> appMenuFor(UserRole? role) {
  if (role != UserRole.patient) return appMenuItems;
  return appMenuItems.where((item) => item.route != '/stock').toList();
}

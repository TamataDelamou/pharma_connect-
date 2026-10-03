import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/navigation/sidebar_navigation.dart';
import '../modules/auth/providers/auth_provider.dart';
import 'app_back.dart';
import 'app_menu.dart';
import 'route_titles.dart';

/// C226 : cadre de navigation commun à toutes les routes connectées
/// (ShellRoute de app_router.dart).
/// - Largeur ≥ [wideBreakpoint] : barre latérale toujours visible à gauche.
/// - Plus étroit (téléphone, cible principale) : barre du haut avec le titre
///   de l'écran, une flèche retour (sauf sur /dashboard) et un bouton menu qui
///   ouvre un tiroir contenant le même menu.
/// - Bouton retour du système (PopScope) : même logique que la flèche
///   (app_back.dart) ; sur /dashboard, il ferme l'application normalement.
class AppShell extends StatefulWidget {
  static const double wideBreakpoint = 900;

  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarExpanded = true;

  /// C231 : déconnexion depuis le menu, après confirmation.
  Future<void> _confirmLogout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Déconnexion',
      message: 'Voulez-vous vous déconnecter ?',
      confirmText: 'Se déconnecter',
    );
    if (!confirmed || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final state = router.state;
        final path = state.uri.path;
        // Écrans racines : pas de flèche, le retour du système ferme
        // l'application. C228 : « Complétez votre profil » en fait partie (un
        // retour vers /dashboard y reviendrait aussitôt).
        final isDashboard = path == '/dashboard' || path == '/complete-profile';
        return PopScope(
          canPop: isDashboard,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) goBack(context);
          },
          child: LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= AppShell.wideBreakpoint
                ? _buildWide(path)
                : _buildNarrow(
                    path: path,
                    title: titleForRoute(pattern: state.fullPath, path: path),
                    showBack: !isDashboard,
                  ),
          ),
        );
      },
    );
  }

  SidebarNavigation _menu(
    String path, {
    required bool expanded,
    VoidCallback? onToggleExpand,
    VoidCallback? onNavigate,
  }) {
    final role = context.watch<AuthProvider>().effectiveRole;
    return SidebarNavigation(
      items: appMenuFor(role),
      currentRoute: path,
      expanded: expanded,
      onToggleExpand: onToggleExpand,
      onItemSelected: (route) {
        onNavigate?.call();
        context.go(route);
      },
      onLogout: () {
        onNavigate?.call();
        _confirmLogout();
      },
    );
  }

  Widget _buildWide(String path) {
    return Scaffold(
      body: Row(
        children: [
          _menu(
            path,
            expanded: _sidebarExpanded,
            onToggleExpand: () =>
                setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildNarrow({
    required String path,
    required String title,
    required bool showBack,
  }) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PharmaConnectColors.primaryDeep,
        foregroundColor: PharmaConnectColors.textPrimary,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => goBack(context),
              )
            : null,
        title: Text(
          title,
          style: PharmaConnectTypography.heading3,
          maxLines: 1, // C233 : une seule ligne, coupée avec « … ».
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Builder(
        builder: (context) => Drawer(
          backgroundColor: PharmaConnectColors.primaryDeep,
          child: SafeArea(
            child: _menu(
              path,
              expanded: true,
              onNavigate: () => Scaffold.of(context).closeEndDrawer(),
            ),
          ),
        ),
      ),
      body: widget.child,
    );
  }
}

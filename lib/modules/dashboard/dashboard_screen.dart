import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/kernel/kernel_badge.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/cards/glass_card.dart';
import '../../core/widgets/navigation/sidebar_navigation.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/models/user_role.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/alert_center.dart';
import 'models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentRoute = '/dashboard';
  bool _sidebarExpanded = true;

  // Audit Module 15 (CNS, 29/08/2026) : quinzième occurrence du motif D6 —
  // le module `teleconsult/` (réservation/suivi de téléconsultations, routé
  // /teleconsult pour un patient et /teleconsult/professional pour un
  // compte `professionnel`) était lui aussi construit et jamais atteignable
  // depuis ce menu. Cas particulier : contrairement à toutes les entrées
  // précédentes (une seule route, montrée à tout le monde malgré ce menu
  // resté non filtré par rôle depuis l'origine — limite pré-existante, hors
  // périmètre de ce correctif ponctuel), CNS a DEUX routes racines
  // distinctes selon le rôle. Plutôt que de n'en exposer qu'une (ce qui
  // aurait laissé l'autre moitié du motif D6 non résolue pour l'un des deux
  // rôles), l'entrée « Téléconsultation » est calculée dans `build()``
  // ci-dessous à partir de `AuthProvider.userRole` plutôt qu'ajoutée en dur
  // à cette liste statique. Le sous-système `pre_consultation` (assistant de
  // pré-consultation, voir le rapport d'audit Module 15 §3 et le registre
  // D26) reste volontairement NON routé : contenu factice (`Random()`)
  // risquant de contrevenir à RG-CNS-01/02, différé par arbitrage explicite
  // du porteur du projet (AskUserQuestion, 29/08/2026).
  //
  // Audit Module 12 (TRC, 29/08/2026) : cause racine identifiée du motif
  // récurrent « module routé mais inatteignable » observé aux Modules 8, 10
  // et 11 (registre des écarts, item D6) — cette liste est l'UNIQUE menu de
  // navigation réel de l'application (SidebarNavigation), et n'avait jamais
  // été mise à jour au fil de la construction des nouveaux modules. Ajout
  // des trois entrées manquantes (Prévision de la demande/Module 11,
  // Traçabilité/Module 12, Alertes/Module 10) — QuickActionGrid ci-dessous
  // reste volontairement inchangé : ses données proviennent de
  // DashboardProvider.fetchData(), entièrement fictives (registre, item
  // C34/D4), un problème distinct et déjà différé.
  //
  // Correctif porteur du projet (29/08/2026, clôture Module 12) : la
  // correction ci-dessus était elle-même incomplète — le module `recall/`
  // (pharmacovigilance, routé /recall, /recall/create, /recall/:id) était
  // lui aussi construit et jamais atteignable, douzième occurrence du même
  // motif D6 (correction de numérotation, 29/08/2026 : cette occurrence
  // avait été comptée « treizième » dans une première version de ce
  // commentaire, alors que les documents d'audit/PV du Module 12 la
  // comptent bien comme la douzième — la treizième est l'entrée
  // Marketplace ci-dessous), découverte seulement à l'occasion de
  // l'unification du rappel avec ce module (registre C41/D21). Ajout de
  // « Rappels » ci-dessous. `pos/` reste volontairement absent de ce menu :
  // sa RLS est correcte mais son écran de caisse vend depuis une liste de
  // produits fictive, sans sélection de lot réel — l'exposer en navigation
  // avant son propre audit dédié induirait en erreur (arbitrage porteur du
  // projet, registre D22).
  //
  // Audit Module 13 (B2B, 29/08/2026) : treizième occurrence du motif D6 —
  // le module `marketplace/` (Approvisionnement B2B, routé /marketplace,
  // /marketplace/offer/:id, /marketplace/order/:id, /marketplace/offer/new)
  // était lui aussi construit et jamais atteignable depuis ce menu (registre
  // D23bis / audit Module 13). Ajout de « Marketplace B2B » ci-dessous. Ce
  // menu n'a toujours pas été vérifié module par module dans son ensemble
  // contre les ~36 dossiers sous lib/modules/ : une revue de navigation
  // dédiée, exhaustive, reste recommandée plutôt que de continuer à
  // découvrir ces trous un par un au fil des audits.
  //
  // Audit Module 14 (FIN, 29/08/2026) : quatorzième occurrence du motif D6 —
  // le module `financing/` (Financement & Crédit fournisseur, routé
  // /financing, /financing/:id, /financing/request/new) était lui aussi
  // construit et jamais atteignable depuis ce menu. Ajout de « Financement »
  // ci-dessous. `iot/` reste volontairement absent de ce menu comme
  // `pos/` ci-dessus : ses routes n'ont été dédupliquées que
  // mécaniquement lors de cet audit (blocage critique de démarrage), sans
  // audit complet du module — l'exposer en navigation avant son propre
  // audit dédié induirait en erreur de la même façon.
  final List<SidebarNavigationItem> _navItems = [
    const SidebarNavigationItem(
      label: 'Tableau de bord',
      icon: Icons.dashboard,
      route: '/dashboard',
    ),
    const SidebarNavigationItem(
      label: 'Recherche',
      icon: Icons.search,
      route: '/search',
    ),
    const SidebarNavigationItem(
      label: 'Catalogue',
      icon: Icons.medication_liquid,
      route: '/catalog',
    ),
    const SidebarNavigationItem(
      label: 'Stock & Lots',
      icon: Icons.inventory,
      route: '/stock',
    ),
    const SidebarNavigationItem(
      label: 'Prévision de la demande',
      icon: Icons.trending_up,
      route: '/stock/forecast',
    ),
    const SidebarNavigationItem(
      label: 'Traçabilité',
      icon: Icons.qr_code_scanner,
      route: '/traceability',
    ),
    const SidebarNavigationItem(
      label: 'Rappels',
      icon: Icons.campaign,
      route: '/recall',
    ),
    const SidebarNavigationItem(
      label: 'Marketplace B2B',
      icon: Icons.storefront,
      route: '/marketplace',
    ),
    const SidebarNavigationItem(
      label: 'Financement',
      icon: Icons.account_balance,
      route: '/financing',
    ),
    const SidebarNavigationItem(
      label: 'Alertes',
      icon: Icons.notifications_active,
      route: '/alerts',
    ),
    const SidebarNavigationItem(
      label: 'Ordonnances',
      icon: Icons.description,
      route: '/prescriptions',
    ),
    const SidebarNavigationItem(
      label: 'Réservations',
      icon: Icons.shopping_cart,
      route: '/reservations',
    ),
    const SidebarNavigationItem(
      label: 'Livraisons',
      icon: Icons.local_shipping,
      route: '/deliveries',
    ),
    // Audit Module 26 (CHN, 05/09/2026) : 24ème occurrence du motif D6 —
    // le module `chains/` (groupements multi-officines, transferts de
    // stock inter-officines, tableau de bord/alertes/rôles
    // d'administration réseau) était lui aussi entièrement construit et
    // routé sans jamais être atteignable depuis ce menu. Exposé sans
    // filtrage par rôle, comme la majorité des entrées ci-dessus (limite
    // pré-existante déjà documentée, hors périmètre de ce correctif) — la
    // visibilité de l'entrée de menu ne fuite aucune donnée, c'est la RLS
    // (corrigée par CHN-5) qui gouverne réellement les accès.
    const SidebarNavigationItem(
      label: 'Multi-officines',
      icon: Icons.store,
      route: '/chains',
    ),
    const SidebarNavigationItem(
      label: 'Administration réseau',
      icon: Icons.hub,
      route: '/network',
    ),
    // Audit Module 27 (REG, 05/09/2026) : 25ème occurrence du motif D6 — le
    // module `regulator/` (signalements de pharmacovigilance, inspections,
    // AMM) était lui aussi entièrement construit et routé (voir REG-2/REG-4
    // du rapport d'audit) sans jamais être atteignable depuis ce menu.
    // Exposé sans filtrage par rôle, comme la quasi-totalité des entrées
    // ci-dessus : c'est la RLS (corrigée en Étape 2, REG-1/REG-5) qui
    // gouverne réellement les accès et adapte le contenu de l'écran
    // lui-même selon le rôle (patient/staff GSG/régulateur).
    const SidebarNavigationItem(
      label: 'Pharmacovigilance',
      icon: Icons.health_and_safety,
      route: '/regulator',
    ),
    // Audit Module 28 (BI), Étape 3 (05/09/2026) : 26ème occurrence du motif
    // D6 — le module `analytics` (tableaux de bord officine/réseau,
    // prévisions IA, export de rapports ; routes `/analytics`,
    // `/analytics/dashboard-editor`, `/analytics/forecast`,
    // `/analytics/export`, toutes désormais fonctionnelles et sécurisées —
    // voir le rapport d'audit BI-1/BI-2/BI-5/BI-6/BI-7/BI-8) n'avait aucune
    // entrée de menu. Exposée sans filtrage par rôle, comme la quasi-totalité
    // des entrées ci-dessus : ce sont les vues "_scoped"/RLS corrigées en
    // Étape 2/3 qui gouvernent réellement ce que chaque compte y voit (un
    // patient obtient des écrans vides, jamais une fuite de CA inter-officines).
    const SidebarNavigationItem(
      label: 'Analytics',
      icon: Icons.insights,
      route: '/analytics',
    ),
    const SidebarNavigationItem(
      label: 'Paramètres',
      icon: Icons.settings,
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchData();
    });
  }

  /// Audit Module 15 (CNS, 29/08/2026) : entrée « Téléconsultation »
  /// calculée selon le rôle connecté (voir le commentaire au-dessus de
  /// `_navItems`) — un compte `professionnel` est envoyé vers
  /// `/teleconsult/professional` (son propre calendrier), tout autre compte
  /// authentifié vers `/teleconsult` (ses propres rendez-vous en tant que
  /// patient).
  List<SidebarNavigationItem> _effectiveNavItems(BuildContext context) {
    final role = context.watch<AuthProvider>().userRole;
    final teleconsultRoute = role == UserRole.professionnel
        ? '/teleconsult/professional'
        : '/teleconsult';
    return [
      ..._navItems,
      SidebarNavigationItem(
        label: 'Téléconsultation',
        icon: Icons.video_call,
        route: teleconsultRoute,
      ),
      // Audit Module 16 (FID, 29/08/2026) : 16ème occurrence de D6. Un
      // patient peut avoir un compte fidélité dans plusieurs officines
      // (loyalty_accounts n'a pas de contrainte d'unicité par patient, une
      // seule par (patient_id, pharmacy_id)) — la route pointe donc vers
      // LoyaltyPharmacySelectScreen (choix/rejoindre une officine), pas
      // directement vers un tableau de bord. Réservé au rôle patient : les
      // policies « Staff manage/view » existent en base (arbitrage porteur
      // du projet, question 2 : programme de base exposé, le reste de la
      // couche gamification — badges/classement/défis/récompenses IA —
      // reste volontairement non routé, même logique que D26) mais aucun
      // écran de gestion staff n'a jamais été construit pour ce module.
      if (role == UserRole.patient)
        const SidebarNavigationItem(
          label: 'Fidélité',
          icon: Icons.card_giftcard,
          route: '/loyalty',
        ),
      // Audit Module 17 (TRI, 30/08/2026) : 17ème occurrence de D6. Le
      // système trouvé sous `triage/` est un triage d'urgences hospitalier
      // interne (infirmier/médecin), pas le questionnaire d'auto-évaluation
      // patient du cahier (écart de périmètre majeur, voir le registre) —
      // corrigé et exposé tel quel, à l'identique du précédent D24
      // (marketplace B2B pharmacie-à-pharmacie). Un compte `professionnel`
      // est envoyé vers `/triage/nurse` (file d'attente + création de
      // dossier), tout autre compte authentifié vers `/triage` (ses propres
      // dossiers, généralement vide — aucun dossier n'est jamais créé par le
      // patient lui-même, seul le personnel en crée).
      SidebarNavigationItem(
        label: 'Triage',
        icon: Icons.emergency,
        route: role == UserRole.professionnel ? '/triage/nurse' : '/triage',
      ),
      // Audit Module 18 (HOM, 30/08/2026) : 18ème occurrence de D6 — le
      // module `homecare` entier (4 routes fonctionnelles, dont l'écran de
      // réservation cassé par le shadowing de route corrigé dans
      // app_router.dart) n'avait aucune entrée de menu, alors qu'il s'agit
      // d'une fonctionnalité « Flagship CARE » du cahier (priorité la plus
      // élevée du pilier CARE). Même motif de routage par rôle que
      // Téléconsultation/Triage.
      SidebarNavigationItem(
        label: 'Soins à domicile',
        icon: Icons.home_repair_service,
        route: role == UserRole.professionnel
            ? '/homecare/professional'
            : '/homecare',
      ),
      // Audit Module 20 (DSN), ouverture (30/08/2026) : 19ème occurrence du
      // motif D6 — le module `healthrecord` (dossier de santé du patient :
      // liste, détail, édition, routes `/healthrecord`, `/healthrecord/:id`,
      // `/healthrecord/edit[/:id]`, déjà fonctionnelles et même déjà
      // corrigées d'un chevauchement de route lors de l'audit Module 18,
      // voir app_router.dart) n'avait aucune entrée de menu. Réservé au
      // rôle patient, comme Fidélité ci-dessus : le code actuel n'implémente
      // que le CRUD du patient sur son propre dossier (fiche médicale
      // auto-déclarée), pas d'écran de consultation dédié pour un
      // professionnel (voir le rapport d'audit — RG-DSN-01, consentement du
      // patient, n'est pas non plus appliqué au niveau RLS, écart consigné
      // au registre) ; exposer cette entrée à `professionnel` inviterait à
      // une page qui ne montre que son propre profil vide, pas celui d'un
      // patient.
      if (role == UserRole.patient)
        const SidebarNavigationItem(
          label: 'Dossier de santé',
          icon: Icons.folder_shared,
          route: '/healthrecord',
        ),
      // Audit Module 22 (FAM), clôture (30/08/2026) : 20ème occurrence du
      // motif D6 — le module `family` (partage consenti de dossier
      // patient↔proche, défis santé, alerte SOS ; routes `/family`,
      // `/family/new`, `/family/alerts`, `/family/sos`, `/family/:id`,
      // toutes fonctionnelles et déjà réordonnancées contre le shadowing
      // go_router lors du balayage C69) n'avait aucune entrée de menu.
      // Décision explicite du porteur du projet (arbitrage de clôture) :
      // exposer dès maintenant, les deux tables de base et les 4 tables
      // annexes (défis, SOS) étant désormais entièrement sécurisées et
      // validées par exécution réelle (12/12 tests Postgres 16, voir le
      // rapport d'audit §7.7). Contrairement à Téléconsultation/
      // Triage/Soins à domicile ci-dessus, ce module n'a pas de rôle
      // "family_member" dédié côté schéma — patient et proche sont tous
      // deux de simples comptes authentifiés distingués uniquement par
      // leur position dans `family_links` — l'entrée est donc exposée à
      // tout rôle authentifié, sans filtrage par `UserRole`. Deux entrées
      // ajoutées, comme explicitement demandé à la clôture : « Famille »
      // (liste des liens, accès à l'ajout de proche/alertes/journal) et
      // un accès direct « SOS Urgence » (`/family/sos`), la nature
      // urgente de cette fonctionnalité justifiant qu'elle ne soit pas
      // reléguée à un sous-écran de la précédente.
      const SidebarNavigationItem(
        label: 'Famille',
        icon: Icons.family_restroom,
        route: '/family',
      ),
      const SidebarNavigationItem(
        label: 'SOS Urgence',
        icon: Icons.sos,
        route: '/family/sos',
      ),
      // Audit Module 23 (HOP), clôture (30/08/2026) : 21ème occurrence du
      // motif D6 — le module `hospitals` (annuaire de structures
      // partenaires, filtrable type/ville/urgences, détail avec
      // licence/accréditation et temps d'attente en temps réel ; routes
      // `/hospitals`, `/hospitals/select`, `/hospitals/:id`,
      // `/hospitals/:id/wait-times`) n'avait aucune entrée de menu.
      // Décision explicite du porteur du projet (arbitrage de clôture,
      // scénario « valider les correctifs techniques, différer les
      // chantiers lourds ») : exposer dès maintenant — l'annuaire et le
      // détail sont désormais fonctionnels et sécurisés (HOP-1 : écriture
      // back-office réservée à `is_gsg_admin()`, validée par 14/14 tests
      // réels ; HOP-2/HOP-3 : import cassé et référence de champ
      // inexistante corrigés). Le volet prescription/suivi d'examens et
      // transmission DSN, absent du cahier réalisé (D39), et le back-office
      // de gestion (HOP-4, D40), tous deux différés, n'affectent pas
      // l'usage en consultation/orientation ici exposé. Aucun rôle
      // "hospital_staff" dédié côté schéma pour ce module — entrée exposée
      // à tout rôle authentifié, comme Famille ci-dessus.
      const SidebarNavigationItem(
        label: 'Établissements de santé',
        icon: Icons.local_hospital,
        route: '/hospitals',
      ),
      // Audit Module 24 (ASR), clôture (30/08/2026) : 22ème occurrence du
      // motif D6 (le rapport d'audit Étape 1 l'avait initialement comptée
      // « 23ème » par erreur ; la séquence réelle du registre, incrément par
      // incrément depuis Module 16, place Établissements de santé
      // ci-dessus au 21ème rang — ce module est donc le 22ème, corrigé ici)
      // — le module `insurance` (adhésion à un tiers-payant, consultation
      // du contrat, simulateur de couverture, création de contrat, suivi de
      // remboursement ; routes `/insurance`, `/insurance/staff`,
      // `/insurance/enroll/new`, `/insurance/enroll/:id`,
      // `/insurance/reimbursement/:claimId`) n'avait aucune entrée de menu.
      // Décision explicite du porteur du projet (arbitrage de clôture) :
      // exposer immédiatement — la route racine et le formulaire de
      // création sont désormais fonctionnels et sécurisés (ASR-1/ASR-2 :
      // écriture back-office réservée à `is_gsg_admin()`, validée par
      // 23/23 tests réels ; ASR-3/ASR-4 : écran de création et suivi de
      // remboursement reconnectés à des données réelles ; ASR-8 : défaut de
      // compilation bloquant corrigé). Les 3 écarts de périmètre cahier
      // (télétransmission, portail assureur, écran de rattachement/liste de
      // sinistres dédié) et l'ergonomie des sélecteurs patient/plan,
      // différés (voir le registre), n'affectent pas l'usage en
      // consultation/simulation/création ici exposé. Aucun rôle
      // "insurance_staff" dédié côté schéma — entrée exposée à tout rôle
      // authentifié, comme Famille/Établissements de santé ci-dessus (le
      // volet staff, `/insurance/staff`, n'a de sens que pour un compte
      // `is_gsg_admin()`, non identifié par `UserRole` dans ce menu).
      const SidebarNavigationItem(
        label: 'Assurance & Tiers-payant',
        icon: Icons.health_and_safety,
        route: '/insurance',
      ),
      // Audit Module 25 (PRE), Étapes 2/3 (30/08/2026), sur instruction
      // explicite du porteur du projet (appliquer immédiatement, sans
      // attendre une clôture séparée comme pour les occurrences
      // précédentes) : 23ème occurrence du motif D6 — le module
      // `eprescription` (émission d'ordonnance électronique, suivi de
      // statut, scan OCR d'ordonnance papier ; routes `/eprescription`,
      // `/eprescription/doctor`, `/eprescription/pharmacy`,
      // `/eprescription/scan`, `/eprescription/new`) n'avait aucune entrée
      // de menu — seule « Ordonnances » (Module 5/ORD, `/prescriptions`)
      // était exposée, module distinct. Exposition immédiate justifiée par
      // la correction de RG-PRE-01 (PRE-2 : seul un compte
      // `role='professionnel'` ET `professional_profiles.is_verified`
      // peut désormais émettre une ordonnance opposable, validé par 10/10
      // tests Postgres 16 réels) et des 3 défauts de compilation corrigés
      // (PRE-1/PRE-3/PRE-4). Aucun rôle "eprescription_staff" dédié côté
      // schéma — entrée exposée à tout rôle authentifié, comme
      // Famille/Établissements de santé/Assurance ci-dessus.
      const SidebarNavigationItem(
        label: 'e-Prescriptions',
        icon: Icons.description,
        route: '/eprescription',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final navItems = _effectiveNavItems(context);

    return Scaffold(
      body: Row(
        children: [
          SidebarNavigation(
            items: navItems,
            currentRoute: _currentRoute,
            expanded: _sidebarExpanded,
            onItemSelected: (route) {
              setState(() => _currentRoute = route);
              context.go(route);
            },
            onToggleExpand: () {
              setState(() => _sidebarExpanded = !_sidebarExpanded);
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: dashboard.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tableau de bord',
                                    style: PharmaConnectTypography.heading1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Bienvenue sur PharmaConnect — Infrastructure numérique du circuit pharmaceutique',
                                    style: PharmaConnectTypography.body2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const KernelBadge(),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              backgroundColor: PharmaConnectColors.accentCyan
                                  .withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person,
                                color: PharmaConnectColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ===== ACTIONS RAPIDES =====
                        QuickActionGrid(actions: dashboard.data.actions),
                        const SizedBox(height: 32),

                        // ===== INDICATEURS CLÉS (3 cartes stats) =====
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.2,
                          children: dashboard.data.stats.map((stat) {
                            return _buildStatCard(stat);
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // ===== ACTIVITÉ RÉCENTE + ALERTES (2 colonnes) =====
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: ActivityTimeline(
                                  activities: dashboard.data.activities,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: AlertCenter(
                                  alerts: dashboard.data.alerts,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(StatCardData stat) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, color: stat.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stat.title,
                  style: PharmaConnectTypography.body2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  stat.value,
                  style: PharmaConnectTypography.kpiMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stat.change,
                  style: PharmaConnectTypography.body2.copyWith(
                    color: stat.color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

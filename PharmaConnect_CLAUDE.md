# CLAUDE.md — PharmaConnect

Infrastructure numérique du circuit pharmaceutique et des soins à domicile en Afrique de l'Ouest (Connect Care / Connect Pharma / Connect Supply). Application Flutter, backend Supabase, conçue pour s'intégrer nativement au GSG Platform Kernel.

Référence produit : *Cahier de Conception PharmaConnect v2.1* (34 modules, 66 règles de gestion). Référence infrastructure : *GSG Platform Kernel — cahier de conception v3.0*. Référence authentification : *Modèle d'authentification Supabase — Migration Firebase vers Supabase*. Ce fichier documente l'état du **code**, pas seulement l'intention du cahier — mets-le à jour à chaque changement structurant plutôt que de laisser le cahier de conception et le dépôt diverger.

## État au 04/10/2026 — à lire en premier

Les sections « Mise à jour » et « État du projet » plus bas sont l'historique d'août 2026 : plusieurs constats y sont dépassés (nombre de tests, état de la CI, commandes, chantiers). La référence vivante est le registre `docs/PharmaConnect_Registre_Ecarts_A_Verifier.md` (décisions D1–D67, tickets C1–C239, section A « à prouver avant pilote » A31–A39).

**Base de données**
- 123 migrations dans `supabase/migrations/`, toutes appliquées sur le projet en ligne depuis le 02/10/2026 (`supabase db push`, après sauvegarde dans `..\pharma_connect_backups\20261002_avant_push_22\` et répétition locale). La base en ligne ne contient aucune donnée réelle (catalogue de démonstration de `seed.sql`, 2 comptes d'essai sans profil).
- Règles d'accès durcies par l'audit C193–C225 ; principes à respecter dans tout nouveau code :
  - rôle déclaré ≠ rôle vérifié : les droits passent par `has_verified_role()` ; un compte non validé utilise l'application comme un patient, avec un bandeau d'état (`my_account_status()`, `AuthProvider.effectiveRole`) — D58, D64, D66 ;
  - colonnes sensibles verrouillées (`profiles.role`, `pharmacy_id`, vérification des professionnels) ; personnel d'officine rattaché par invitation du titulaire — D59 ;
  - données de santé : accès par lien de soin, accès d'urgence tracé de 24 heures depuis le triage, journal d'audit réservé à GSG — D61, D63 ;
  - officine suspendue ou non validée : plus aucun droit, rattachement conservé (C210) ;
  - comptoir : vente sur le vrai stock (lots par péremption), prix imposé par le serveur, remboursement selon règle avec quarantaine, caisse du caissier obligatoire pour les espèces — D57, D60, D62 ;
  - paiement : jamais confirmé par le client ; l'officine qui encaisse (ou GSG) confirme, rembourse et règle les échéances par fonctions serveur journalisées ; recharge du portefeuille désactivée — D67 ;
  - vues d'analyse fermées à `anon` ; adresses de livraison, livreurs, administrateurs et paramètres GSG limités aux parties concernées — D65 ;
  - toute écriture sensible passe par une fonction `SECURITY DEFINER` (`set search_path = public`, droits retirés à `public` et `anon`), jamais par une écriture directe du client.

**Façon de travailler**
- Ne jamais modifier une migration existante : une nouvelle migration par ticket, avec un en-tête qui explique le défaut et la décision.
- Chaque ticket a son test dans `supabase/sql_tests/` : une transaction terminée par `rollback`, identités simulées (`request.jwt.claims` + `set local role authenticated`), une ligne `CAS n OK/ECHEC` par cas ; lancer tous les fichiers après `supabase db reset --local` (liste et commandes : `supabase/sql_tests/README.md`).
- Chaque décision du porteur du projet est inscrite au registre (Dxx), chaque ticket aussi (Cxx : constat, résolution, commits, tests).
- Commits : fichiers listés explicitement, jamais `git add -A`. Sous Windows, l'index git est en LF et beaucoup de fichiers du poste sont en CRLF : écrire en LF et ne jamais committer un changement de fins de ligne seul.

**Couleurs et thème (C234)**
- Thème clair (blanc cassé) par défaut ; le thème sombre est conservé comme second thème, sans sélecteur tant que l'écran Paramètres (C227) n'existe pas.
- Les couleurs se lisent uniquement par rôle : `context.palette` (`PharmaConnectPalette`, `lib/core/theme/palette.dart`) et `context.text` pour les styles de texte. Le code sans `BuildContext` (modèles, fournisseurs) nomme un rôle par `ColorRole`, que l'écran traduit par `role.of(context.palette)`.
- Aucune couleur en dur hors de `lib/core/theme` : ni `Color(0x…)`, ni `Colors.white` / `Colors.black`, ni couleur Material nommée. Sur un fond de couleur pleine, le texte prend `onPrimary` ou `onDanger`. Garde-fou : `scripts/ci/check_no_hardcoded_color.sh`.
- Couleurs fixes, qui ne dépendent pas du thème : seulement dans `PharmaConnectFixedColors` (marque d'un tiers, métaux des paliers de fidélité, texte sur l'image de la caméra).
- `PharmaConnectTypography` ne porte pas de couleur ; `mono` (chasse fixe) est réservé aux codes, montants et références.
- `KernelUi.enabled` (`lib/core/kernel/kernel_ui.dart`) reste à `false` tant que D2 n'est pas levé : le badge et l'indicateur Kernel ne s'affichent sur aucun écran.
- Contrôle visuel : `flutter test tool/screenshots/c234_contact_sheets_test.dart` (planches de toutes les routes sans paramètre à 360 px, dans `build/c234_screenshots/planches/`).

**Vérifications de référence (04/10/2026)**
- Tests SQL : 18 fichiers et `concurrency_numbering.sh`, tous OK.
- `flutter analyze lib/` : 0 erreur, 266 avertissements, 224 infos (490 au total).
- `flutter test` : 104 réussis, 23 en échec (échecs connus : tests écrits pour les anciennes données factices, voir A33).
- `flutter build apk --debug` : réussi.

**Poste de développement**
- Ordre imposé par la mémoire disponible : tests SQL d'abord, puis arrêt de Supabase, Docker Desktop et des démons Gradle, puis `flutter analyze`, `flutter test` et `flutter build`.
- `C:\Users\delam\.wslconfig` : `memory=5GB`, `swap=4GB` ; fichier d'échange Windows : 8 Go ; extensions Java/Gradle désactivées dans l'espace de travail VS Code de ce projet ; arrêter les conteneurs TradeLink (`docker stop tradelink-kyc-worker tradelink-clamav`) en début de session, sans les supprimer.

**Avant tout pilote (registre, section A)** : la connexion par e-mail avec code à 6 chiffres est prouvée en ligne (A31, SMTP Brevo, expéditeur `no-reply@globalservicegroupe.com`) ; SMS et WhatsApp restent non branchés ; parcours complets avec de vrais comptes jamais joués (A32) ; CI rouge (A33) ; paiement opérateur Orange/MTN/Moov non branché (A34) ; mode hors ligne absent (A35) ; fonctions « IA » simulées (A36) ; Kernel GSG différé (A37). Prochaine étape : A32, les parcours réels.

## Mise à jour (27/08/2026, suite) — P1 (fin) : test end-to-end avec un vrai compte bloqué par une limite Supabase, pas par le code

Tentative de créer un compte de démo via le vrai flux d'inscription (app lancée en `flutter run -d windows` contre le projet réel) pour valider les nouvelles politiques RLS d'écriture. **Deux vrais blocages trouvés, tous deux côté configuration Supabase, aucun dans le code produit :**

1. **SMS/WhatsApp indisponible** — confirmé via l'API de gestion Supabase (`external_phone_enabled: false`) : Twilio est déclaré comme fournisseur mais pas branché. Seule l'inscription par email fonctionne sur ce projet.
2. **L'inscription par email ne délivre pas de code exploitable** — le template email par défaut du projet (`mailer_templates_magic_link_content`) ne contient que `{{ .ConfirmationURL }}`, jamais `{{ .Token }}` : `signInWithOtp()` envoie bien un code en interne, mais l'utilisateur ne reçoit qu'un lien, pas de code à saisir dans `otp_verification_screen.dart`. Tentative de correction via l'API de gestion (`PATCH /v1/projects/{ref}/config/auth`) : **refusée par Supabase** (`400 : "Email template modification is not available for free tier projects using the default email provider. Please upgrade your plan or configure a custom SMTP provider."`) — restriction de plateforme, pas un problème de permissions ou de code. Trouvé au passage et corrigé (accepté par l'API, contrairement au template) : `mailer_otp_length` était à **8** alors que `otp_verification_screen.dart` n'accepte que des codes à **6** caractères (`_otpController.text.length != 6`) — remis à 6 sur le projet réel, ce point-là est réglé même si le template reste bloqué.

**Décision prise avec l'utilisateur** : reporter le test end-to-end plutôt que de configurer un SMTP tiers ou upgrader le plan Supabase maintenant. Le code et la migration P1 restent considérés comme faits et vérifiés — vérification structurelle déjà faite (colonne `pharmacy_id`, fonction `is_pharmacy_staff`, 10 policies confirmées via `pg_policies` sur le projet réel), seule la vérification comportementale via un compte réellement authentifié reste ouverte.

**Non fait, à reprendre quand ce point sera débloqué** : créer le compte de démo, lui assigner un `pharmacy_id` (manuellement via le SQL editor en attendant un flux d'assignation), vérifier que le staff peut écrire son propre stock et pas celui d'une autre officine.

## Mise à jour (27/08/2026, suite) — P1 : politiques RLS d'écriture par rôle (staff officine/livreur), branche dédiée `feature/staff-rls-write-policies`

Décision de conception confirmée avec l'utilisateur avant d'écrire quoi que ce soit : le rattachement utilisateur↔officine passe par un **rôle sur le compte existant** (`public.profiles.role`, déjà présent depuis la migration `profiles`) plutôt qu'une table de rattachement séparée — plus simple à brancher sur le schéma RLS actuel, cohérent avec `RG-AUT-01` déjà en place. Nouvelle migration `20260827002000_staff_write_policies.sql` : colonne `profiles.pharmacy_id` (nullable, remplie après vérification de licence — pas à l'auto-inscription, aucune UI ne l'écrit aujourd'hui, chantier séparé), fonction `is_pharmacy_staff(pharmacy_id)` (`SECURITY DEFINER`, `search_path` verrouillé), et 10 nouvelles politiques d'écriture : `stock_items`/`stock_batches` en gestion complète pour le staff (`role = 'pharmacien'` + `pharmacy_id` correspondant), `stock_movements`/`stock_adjustments` en **insertion seule** (journaux, jamais modifiés/supprimés) ; côté livraison, rattachement déjà existant via `delivery_drivers.user_id` (pas besoin de `pharmacy_id`) — le livreur met à jour statut/position sur ses propres livraisons/tournées et insère la preuve de livraison, mais ne crée ni ne supprime rien (assignation par l'officine/dispatch, hors périmètre). Poussée et vérifiée sur le projet réel (`pg_policies` : les 10 policies présentes, colonne et fonction confirmées).

**Trouvaille en cours de route, plus importante que la migration elle-même** : `public.profiles` n'était jusqu'ici **jamais écrite par le produit**. `register_screen.dart` collecte nom et rôle à l'inscription, mais `auth.setRole(_selectedRole)` ne faisait que positionner un état en mémoire sur `AuthProvider` (`_userRole`) — jamais persisté. Le nom (`_nameController.text`) n'était même pas transmis au provider : saisi puis silencieusement jeté. Conséquence directe pour ce chantier : sans profil persisté, les nouvelles politiques RLS n'auraient jamais eu de `role`/`pharmacy_id` à lire — la migration aurait été inerte pour tout le monde. Corrigé, pas seulement documenté :
- Nouveau `lib/modules/auth/services/profile_service.dart` (`ProfileService.upsertProfile`).
- `AuthProvider.verifyPhoneOtp()`/`verifyEmailOtp()` acceptent désormais `fullName`/`role` optionnels et appellent l'upsert **après** vérification réussie du code (c'est là qu'un `auth.uid()` réel existe) — écriture en best-effort (`try/catch` local documenté) : une panne réseau sur ce point ne doit pas transformer une connexion déjà réussie en échec.
- `register_screen.dart` transmet désormais `fullName`/`role` via l'`extra` de `/otp` ; `otp_verification_screen.dart` les relaie aux méthodes de vérification. `login_screen.dart` inchangé (aucune UI de rôle) — l'upsert s'exécute quand même à la connexion, avec seulement `phone`/`email`, ce qui garantit qu'un profil minimal existe pour tout compte authentifié, même ceux créés avant ce correctif.

Vérifié : `flutter analyze` 0 erreur (27 infos, +3 attendues — mêmes lints `use_null_aware_elements` déjà présents ailleurs dans le code), `flutter test` 24/42 inchangé (aucune régression), les trois garde-fous CI verts.

**Non fait, hors périmètre** : aucune UI pour assigner `profiles.pharmacy_id` (ni pour l'auto-inscription driver côté `delivery_drivers`) — ça suppose un flux d'assignation post-vérification de licence qui n'existe pas encore côté produit, volontairement laissé en dehors de ce chantier plutôt que d'improviser une hypothèse de conception.

## Mise à jour (27/08/2026, suite) — données de départ chargées dans le projet Supabase réel

`supabase/seed.sql` (nouveau, absent jusqu'ici) charge 6 catégories, 5 fabricants, 20 médicaments (contexte guinéen : Doliprane, Coartem, Amoxicilline...), 1 groupe + 6 officines de la région de Conakry (Kaloum, Dixinn, Ratoma, Matoto, Kipé, Matam — une en statut `pending` pour démontrer RG-AUT-01), et le stock croisé des 6 officines × 20 produits (120 `stock_items` + 120 `stock_batches`, quantités/statuts variés via `random()`, dates d'expiration étalées sur ~2 ans pour donner des cas de rappel/péremption proche).

**Portée volontairement limitée aux tables référentielles/catalogue** (`categories`, `manufacturers`, `products`, `pharmacy_groups`, `pharmacies`, `stock_items`, `stock_batches`) — toutes à lecture ouverte à `authenticated` (`using (true)`), sans dépendance à un compte réel. Les tables à portée personnelle (`profiles`, `wallets`, `prescriptions`, `reservations`, `transactions`, `alerts`, `deliveries`...) restent vides : leurs politiques RLS les limitent à `auth.uid()`, et il n'existe aucun compte `auth.users` réel à qui les rattacher — y insérer des lignes fictives les aurait rendues invisibles depuis l'app (donc sans valeur de démo) tout en risquant de donner une fausse impression de couverture.

**Chargement effectué via l'API de gestion Supabase** (`POST /v1/projects/{ref}/database/query`, authentifiée par l'access token déjà utilisé pour `supabase link`/`db push`), pas via `npx supabase db push --include-seed` : ce dernier a bien détecté et « appliqué » le fichier au premier passage, mais un second passage après correction (voir bug ci-dessous) s'est contenté de mettre à jour un hash de suivi interne sans réexécuter le SQL — comportement du CLI non fiable constaté empiriquement, contourné en exécutant le contenu de `seed.sql` directement.

**Un vrai bug trouvé au premier chargement** : les quantités de stock utilisaient `cross join lateral (select floor(random()*161)::int as qty) q` — une sous-requête LATERAL **non corrélée** (qui ne référence aucune colonne de la ligne externe). Le planificateur Postgres l'a hissée et évaluée **une seule fois pour les 120 lignes** au lieu d'une fois par ligne : les 120 `stock_items` se sont retrouvés avec la même quantité, donc tous en statut `inStock` — aucune variété (`critical`/`lowStock`/`outOfStock`). Confirmé avec l'utilisateur avant de vider les 120 lignes (action destructive sur la base distante, bloquée par le classificateur de permissions jusqu'à confirmation explicite). Corrigé en corrélant explicitement chaque LATERAL à `ph.id`/`pr.id` via une clause `where` (empêche le hissage) ; rechargé et vérifié : distribution réelle (105 `inStock`, 10 `lowStock`, 5 `critical`), exactement 6 lignes par produit, aucune `reserved_quantity > total_quantity`.

`seed.sql` est idempotent : `on conflict (id) do nothing` sur les tables à id explicite (catalogue, officines), garde `where not exists (select 1 from ... limit 1)` sur `stock_items`/`stock_batches` (ids générés côté serveur, pas de clé naturelle à opposer).

**Non fait, hors périmètre** : aucune donnée personnelle (comptes, réservations, transactions...) — nécessiterait de vrais comptes `auth.users`, hors de portée d'un seed SQL direct sans passer par le flux d'inscription réel de l'app.

## Mise à jour (27/08/2026, suite) — fusion des 4 branches en attente dans `main`

`main` était resté en retard sur trois branches de travail non fusionnées (`test/expand-coverage`, `feature/supabase-backend`, `chore/update-outdated-packages`), au point que les cahiers documentaient des chantiers « faits » que `main` lui-même ne contenait pas encore. Fusionné dans l'ordre : `feature/supabase-backend` (superset de `test/expand-coverage`, qui en est l'ancêtre direct — un seul merge suffisait pour les deux) puis `chore/update-outdated-packages`. Le premier merge n'a produit aucun conflit ; le second a eu un conflit sur ce fichier (les deux branches avaient chacune documenté la mise à jour des paquets, avec un texte légèrement différent) — résolu en gardant la version la plus détaillée plutôt qu'en tranchant arbitrairement (voir section « paquets obsolètes » plus bas, dont l'intro est corrigée pour refléter la fusion du 27/08). `main` porte désormais tout le travail des quatre branches ; aucune n'a été supprimée (nettoyage laissé à l'utilisateur).

Vérifié après fusion, sur `main` reconstitué (`flutter pub get` relancé pour prendre en compte les deux `pubspec.yaml` fusionnés) : `flutter analyze` **0 erreur, 24 infos de style** — en baisse par rapport aux 64/66 documentés séparément sur les branches avant fusion, `flutter_lints` 3.0→6.0 (fusionné avec les paquets) ayant changé l'ensemble de règles actives, pas une régression. `flutter test` **24/42**, inchangé (mêmes 18 échecs attendus, `PostgrestException` faute de backend réel derrière les tests isolés). Les trois garde-fous CI kernel-compliance verts.

## Mise à jour (27/08/2026, suite) — dernier écran placeholder implémenté (`/transactions/:id`)

Chantier ajouté en commit dédié sur `feature/supabase-backend` (déjà la branche courante suite au chantier 2b ci-dessous ; pas de branche isolée pour un changement aussi ciblé — un seul écran + une ligne de routeur). Nouveau `TransactionDetailScreen` (`lib/modules/payments/screens/transaction_detail_screen.dart`) : branché sur `PaymentProvider.loadTransaction(id)` déjà présent (aucune modification du provider nécessaire). Affiche l'en-tête (icône selon `PaymentMethod`, nom de pharmacie, id, badge de statut, montant final) puis le détail complet du `Transaction` (montant, frais, cashback si non nuls, montant final, méthode, statut, pharmacie, date de création, date de complétion/remboursement si présentes, références, notes) — mêmes gabarits visuels que `StockDetailScreen`/`transaction_list_tile.dart` (`GlassCard`, `KernelBadge`, en-tête avec bouton retour).

`app_router.dart` : route `/transactions/:id` pointe désormais sur `TransactionDetailScreen(transactionId: id)` au lieu de `PlaceholderScreen`. L'import de `PlaceholderScreen` a été retiré du fichier — c'était son seul usage restant dans le routeur.

Vérifié : `flutter analyze` 0 erreur (toujours 64 infos de style pré-existantes), `flutter test` toujours 24/42 (aucune régression, les 18 échecs restent ceux documentés dans la mise à jour 2b ci-dessous), les trois garde-fous CI kernel-compliance verts.

**Dernier écran placeholder du produit résolu** — voir Chantiers ouverts, l'item 3 est maintenant entièrement clos (16/17 le 27/08 + ce dernier).

## Mise à jour (27/08/2026, suite) — 2b : projet Supabase réel provisionné, migrations appliquées, `supabase_service.dart` branché

L'utilisateur a créé un projet Supabase distant (`qemizapoldevapmygryp.supabase.co`) et fourni la clé anon/publishable, un access token personnel (usage unique : authentifier le CLI, jamais écrit dans un fichier suivi par git) et le mot de passe de la base Postgres (usage unique : `supabase link`/`db push`). Aucun Docker requis : le CLI a été exécuté via `npx supabase` (téléchargé à la volée, pas d'installation globale) plutôt que d'attendre une installation locale.

`npx supabase link --project-ref qemizapoldevapmygryp` puis `npx supabase db push --linked --include-all` : **les 15 migrations sont appliquées avec succès**, confirmé avec `npx supabase migration list --linked` (les 15 identifiants `local` et `remote` correspondent exactement). `lib/core/services/supabase_service.dart` a ses vraies valeurs (`supabaseUrl`/`supabaseAnonKey`) à la place des placeholders `votre-projet.supabase.co`/`votre-clé-anon` — la clé anon est une valeur publique par construction (destinée au client), sans risque à committer. L'access token et le mot de passe base n'ont servi qu'aux commandes CLI de cette session ; `supabase/.temp` et `supabase/.branches` (où le CLI local aurait pu écrire des informations de session) étaient déjà dans `.gitignore` avant ce chantier.

**Chantier 2b clôturé** — c'était le seul point Kernel/Supabase encore ouvert (le schéma existait déjà via 2a, le code CRUD existait déjà via 2c, il ne manquait que le backend réel derrière).

Vérifié après coup : `flutter analyze` toujours 0 erreur. `flutter test` toujours **24/42** — inchangé, et c'est attendu : les 18 tests qui échouaient pointent délibérément sur `https://example.supabase.co` dans leur propre `setUpAll` (isolation volontaire des tests vis-à-vis d'un vrai backend), donc le nouveau projet réel ne les affecte pas. La preuve que le vrai projet fonctionne est le résultat propre de `db push`/`migration list` ci-dessus, pas `flutter test`.

**Non fait, hors périmètre de ce chantier** : aucune donnée de départ (seed) n'a été chargée — les 33 tables existent mais sont vides, l'app n'a donc encore rien à afficher de réel en la lançant contre ce projet. Câblage `PowerSync` (hors-ligne officine) et politiques RLS par rôle restent différés comme documenté dans la mise à jour P0 ci-dessous.

## Mise à jour (27/08/2026, suite) — P0 : couche de persistance réelle écrite pour les 12 modules mockés (branche dédiée `feature/supabase-backend`)

Chantier sur `feature/supabase-backend`, créée depuis `test/expand-coverage` (pas depuis `main`, qui n'a pas encore le correctif des 6 providers manquants — voir mise à jour ci-dessous). **Décision explicite prise avec l'utilisateur avant de commencer :** aucun projet Supabase réel n'a été provisionné (ni local via `supabase start` — Docker absent de cet environnement — ni distant — création de compte/connexion OAuth hors de portée d'une session de code). Le chantier s'est donc limité à **écrire le code contre le schéma déjà migré**, sans pouvoir l'exécuter contre une vraie base. `lib/core/services/supabase_service.dart` garde volontairement ses placeholders (`https://votre-projet.supabase.co` / `votre-clé-anon`) : les y remplacer sans projet réel derrière aurait été plus trompeur que de les laisser explicites.

**Les 14 services mockés en mémoire ont été convertis un par un** (`auth` était déjà réel, `dashboard` n'a pas de table — pure agrégation) : `catalog`, `alerts`, `admin`, `coldchain`, `recall`, `traceability`, `stock`, `delivery`, `payments`, `prescriptions`, `reservations`, `search`. Chaque service utilise désormais `SupabaseService().client.from('table')` avec `select`/`insert`/`update`/`delete` réels, en respectant strictement les signatures publiques déjà consommées par les providers — aucun provider n'a eu besoin d'être modifié. Ajout du paquet `uuid` (`^4.4.0`) : chaque `createX()` génère son `id` **côté client** avant l'écriture, comme demandé, plutôt que de compter sur le `default gen_random_uuid()` du schéma.

**Sérialisation JSON ajoutée à ~35 modèles** (`fromJson`/`toJson`, snake_case ↔ camelCase) — quasiment aucun n'en avait avant ce chantier. Patron reproduit partout : les listes imbriquées (`TraceableBatch.movements`, `Recall.affectedBatches`, `Prescription.items`...) sont lues via l'embed PostgREST (`select('*, table_enfant(*)')`) mais **jamais réécrites** par le parent — chaque table enfant reste gérée indépendamment par son service, en respectant les tables séparées du schéma.

**Trois écarts de modélisation déjà documentés dans les migrations (priorité 5) ont dû être vraiment résolus, pas seulement commentés :**
- `search` n'a pas de table dédiée (voir `20260827001500_search.sql`) : `SearchResult`/`AvailabilityResult` sont désormais calculés en interrogeant réellement `products` + `stock_items` (jointe à `pharmacies`) au moment de la recherche, remplaçant le générateur aléatoire de stock qui tournait en mémoire. Seul `search_history` est une vraie table, câblée à l'utilisateur authentifié (`SupabaseService().currentUser?.id`).
- Le modèle `Pharmacy` de `search` attend des champs (`isOpenNow`, `isOpen24h`, `isOnDuty`, `openingHours`) qui n'existent pas dans `public.pharmacies` (aucune notion d'horaires en base) — valeurs par défaut documentées en commentaire dans `Pharmacy.fromJson`, pas une vraie source de vérité.
- `stock_items.pharmacy_id` est `NOT NULL` en base mais `StockItem` (Dart) n'a toujours pas de champ pharmacie (même écart que documenté en priorité 5) : `StockService` lit le stock toutes officines confondues, faute d'un concept de « pharmacie sélectionnée » ailleurs dans l'app.

**Deux méthodes qui étaient des stubs non fonctionnels ont été réellement implémentées en cours de route** (pas juste portées) : `PaymentService.getInstallment()` retournait des données simulées en ignorant l'id reçu ; `payInstallment()` ne modifiait jamais rien. Les deux interrogent/écrivent désormais réellement `installments`/`installment_payments`. De même, `TraceabilityService.getVerificationHistory()` retournait un historique fictif à une entrée : il lit désormais réellement `verification_scans`.

**Incohérences trouvées et corrigées au passage**, du même genre que celles documentées en priorité 8 (§2 points 14-15 de `REFERENTIEL_ARCHITECTE.md`) : `DeliveryService.getDriver()`/`getRoute()` retournaient un élément arbitraire de la liste au lieu de `null` sur un id introuvable, malgré un type de retour nullable déclaré — corrigé pour retourner vraiment `null` (`maybeSingle()`). Même correction sur `PaymentService.getInvoice()`.

**Conséquence attendue et vérifiée sur `flutter test`** : 18 des 42 tests échouent désormais (13 unitaires « nominal », 5 widget) — tous parce qu'aucun projet Supabase réel n'existe derrière `supabase_service.dart`, pas à cause d'un bug. Vérifié en lisant le message d'erreur exact (`PostgrestException`, pas une exception Dart de code cassé). Corrigé au passage : ces 24 fichiers de test ne faisaient jamais `Supabase.initialize()` dans leur `setUpAll` (`AuthProvider` était jusqu'ici le seul provider à en dépendre) — sans ce correctif, les tests échouaient sur une erreur d'initialisation Dart plutôt que sur la vraie cause (absence de backend), ce qui aurait été trompeur. **Ces 18 tests repasseront au vert automatiquement une fois qu'un vrai projet Supabase existera et que ses migrations y seront appliquées — ne pas les modifier pour les faire passer artificiellement.**

Vérifié : `flutter analyze` sur tout `lib/` (0 erreur, 64 infos de style pré-existantes), les trois garde-fous CI kernel-compliance restent verts. `flutter test` est volontairement rouge pour la raison ci-dessus.

**Non fait, hors périmètre de cette session (voir Chantiers ouverts) :** provisionner un vrai projet Supabase (2b) ; câbler `PowerSync` pour le mode hors-ligne officine (jamais commencé) ; étendre les politiques RLS d'écriture par rôle (staff officine/livreur), toujours différées faute de mécanisme de rattachement utilisateur↔officine.

## Mise à jour (27/08/2026, suite) — couverture de tests étoffée (branche dédiée), un vrai bug de production trouvé et corrigé

Chantier sur `test/expand-coverage` (créée depuis `main` propre). Avant d'écrire le moindre test, un premier passage sur `app.dart` a révélé le finding le plus important de cette session : **6 providers sur 14 (`AdminProvider`, `AlertProvider`, `ColdChainProvider`, `RecallProvider`, `StockProvider`, `TraceabilityProvider`) n'étaient jamais enregistrés dans le `MultiProvider` racine**, alors que 20 écrans dans ces 6 modules font `context.read<X>()`/`context.watch<X>()` dessus. Naviguer vers n'importe lequel de ces écrans dans l'app réelle (admin, alertes, chaîne du froid, rappels, stock, traçabilité) aurait levé une `ProviderNotFoundException` et crashé — invisible jusqu'ici faute de test qui construise ces écrans. Corrigé dans `app.dart` (6 imports + 6 `ChangeNotifierProvider` ajoutés) avant d'écrire le moindre test, sinon les tests de ces 6 écrans auraient simplement échoué sur ce même crash.

**27 tests unitaires ajoutés** dans `test/unit/providers/` — un fichier par provider (14/14), nominal + erreur pour 12 d'entre eux, en s'appuyant sur le fait que les services sont déjà des mocks en mémoire déterministes (pas besoin de Mockito) : `loadX()` sans filtre pour le nominal, `loadX('id-inexistant')` pour l'erreur (le `firstWhere` sans `orElse` de chaque service lève naturellement une exception que le provider capture dans `_error`). Deux exceptions documentées plutôt que forcées :
- **`DashboardProvider`** n'a aucun chemin d'erreur (données générées en pur mémoire, ne peut jamais lever d'exception) — un seul test nominal.
- **`StockProvider.loadStockItem()`** : trouvaille — contrairement aux 13 autres services, `StockService.getStockItem()` avale sa propre exception `firstWhere` dans un `try/catch` interne et retourne `null` au lieu de la laisser remonter. `provider.error` est donc **inatteignable** via cette méthode aujourd'hui, une incohérence par rapport au patron utilisé partout ailleurs dans le code. Documenté par un test qui vérifie le comportement réel (pas d'erreur) plutôt que masqué par un test qui prétendrait le contraire.
- **`AuthProvider`** parle à un vrai `GoTrueClient` Supabase (voir `auth_service.dart`) : les branches OTP nominales (envoi/vérification réussis) ne sont pas testables en unitaire sans projet Supabase réel. Les deux tests couvrent ce qui est déterministe sans réseau : la validation synchrone du numéro (erreur, avant tout appel réseau) et les transitions d'état pures `setRole`/`clearError` (nominal). Même construire `AuthProvider()` exige `Supabase.initialize()` — le champ `AuthService _authService` est instancié à la construction, pas à l'usage.

**14 tests widget ajoutés** dans `test/widget/screens/` — un par écran principal de chaque module ayant du code réel (identifié via les routes de premier niveau dans `app_router.dart` : `/login`, `/dashboard`, `/catalog`, `/search`, `/prescriptions`, `/reservations/history`, `/deliveries`, `/wallet`, `/stock`, `/alerts`, `/traceability`, `/recall`, `/coldchain`, `/admin`). Chaque test construit l'écran dans un `MaterialApp` + un seul `ChangeNotifierProvider` (chaque écran principal ne dépend que d'un seul provider — vérifié par grep avant d'écrire les tests) et vérifie l'absence d'exception après le chargement initial.

Ces tests widget ont eux-mêmes trouvé deux bugs réels dans `recall_dashboard_screen.dart`, jamais détectés faute de test qui construise cet écran :
1. Un `RenderFlex overflowed` (dépassement de 3px) — le `Column` du corps n'était pas défilable et le contenu (en-tête + stats + deux graphiques `fl_chart` + filtres + liste) dépassait tout juste la hauteur disponible sur un petit viewport. Corrigé en enveloppant le corps dans un `SingleChildScrollView` (la liste, avant en `Expanded`, passe en `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())`).
2. Une vraie erreur de type (`int` n'est pas un `double`) sur `BarChartRodData.toY: (provider.statistics['averageCompletionRate'] ?? 0) * 100` — le repli `?? 0` est un `int` litéral, donc `int * int = int`, rejeté par `toY` qui exige un `double`. Se déclenchait dès que la statistique était absente/pas encore chargée. Corrigé avec un cast explicite en `double`.

Vérifié : les 42 tests passent (`flutter test` — 1 test d'origine + 27 unitaires + 14 widget), `flutter analyze` ne montre aucune régression (66 infos de style pré-existantes, 0 erreur), les trois garde-fous CI kernel-compliance restent verts. Trouvaille au passage : `.github/workflows/kernel-compliance.yml` n'exécutait jamais `flutter test` — seulement `flutter analyze`. Avec 42 tests désormais réels, les laisser hors CI aurait vidé ce chantier de son intérêt (« chaque nouvelle correction a déjà fait régresser des parties sans qu'on le détecte » vaut aussi pour cette CI elle-même) ; étape `flutter test` ajoutée au workflow.

**Non fait, volontairement hors périmètre :** les modules restants (analytics, marketplace, HomeCare, etc. — 20 modules non entamés, voir Chantiers ouverts item 5) n'ont ni provider ni écran réel à tester. Les écrans secondaires de chaque module (détail, formulaires) ne sont pas couverts — seul l'écran principal par module, comme demandé. Les 66 infos de style relevées par `flutter analyze` sont pré-existantes et sans lien avec ce chantier.

## Mise à jour (27/08/2026, suite) — paquets obsolètes mis à jour (branche dédiée `chore/update-outdated-packages`, fusionnée dans `main` le 27/08/2026)

Chantier traité sur une branche séparée (`chore/update-outdated-packages`, créée depuis `main` propre — les fichiers en attente des priorités précédentes ont d'abord été commités) pour ne pas mélanger montée de version et développement fonctionnel, comme demandé. **Fusionnée dans `main` le 27/08/2026** avec les trois autres branches en attente (voir la mise à jour « fusion des 4 branches » en tête de fichier) — le `pubspec.yaml` de `main` est désormais à jour.

`flutter pub upgrade --major-versions` puis un ajustement manuel de `go_router` (bloqué à 17.5.0 par la résolution automatique alors que 18.0.0 était en fait résolvable) : les **16 dépendances directes** de `pubspec.yaml` sont désormais toutes à jour, dont les trois signalées comme à risque — `go_router` 13→**18**, `mobile_scanner` 3.5→**7.4**, `geolocator` 11→**14**. Les ~16 paquets encore listés par `flutter pub outdated` sont tous transitifs (SDK Flutter, `analyzer`/`build_runner`...), non actionnables depuis ce `pubspec.yaml`.

`flutter analyze` a révélé 13 erreurs de compilation réelles suite à la montée de version, concentrées dans 2 fichiers (aucune dans les trois paquets signalés à risque, contrairement à l'historique du 25/08 où `geolocator` avait déjà cassé la compilation une fois) :
- `notification_service.dart` — `flutter_local_notifications` 16→22 a rendu tous les paramètres positionnels de `initialize`/`show`/`zonedSchedule`/`cancel` nommés, et supprimé `uiLocalNotificationDateInterpretation`/`UILocalNotificationDateInterpretation` (l'interprétation absolue est désormais le seul comportement). Adapté en conséquence.
- `export_service.dart` — `csv` 5→8 a remplacé `ListToCsvConverter` par l'instance top-level `csv` (`csv.encode(rows)`) ; `share_plus` 7→13 a déprécié `Share.shareXFiles(...)` au profit de `SharePlus.instance.share(ShareParams(...))`. Les deux migrés.

Corrigé au passage une dépréciation (pas une erreur) introduite par `geolocator` 11→14 dans `location_service.dart` : `desiredAccuracy` → `locationSettings: LocationSettings(accuracy: ...)`.

Vérifié après coup (sur la branche isolée, avant fusion) : `flutter analyze` revient à son solde d'avant chantier (25 infos de style pré-existantes à l'époque — 66 aujourd'hui après fusion des autres branches, voir plus haut ; 0 erreur, 0 nouvelle dépréciation), `flutter test` passe (l'unique test de l'app rend bien l'écran de login à travers `go_router` 18), et les trois garde-fous CI (`check_no_cross_schema_fk.sh`, `check_no_hardcoded_color.sh`, `check_no_hardcoded_currency.sh`) restent verts.

**Non fait, volontairement hors périmètre :** les ~25 infos de style relevées par `flutter analyze` (`use_build_context_synchronously`, `deprecated_member_use` sur des API du SDK Flutter lui-même comme `activeColor`/`value`) sont pré-existantes, sans lien avec cette montée de version — les corriger ici aurait justement mélangé ce chantier avec autre chose.

## Mise à jour (27/08/2026, suite) — 9 écrans placeholder implémentés sur 17, 8 déjà réels à l'audit

Chantier sur `main` (commit dédié). Avant d'écrire la moindre ligne, audit direct de chaque écran listé comme placeholder plutôt que de faire confiance à l'ancien décompte — écart trouvé : **8 des 17 écrans listés avaient déjà une UI et une logique métier réelles**, jamais `PlaceholderScreen`, sans que ce document ne le documente : `ReservationCheckoutScreen`, `DriverDashboardScreen`, `InstallmentPlanScreen`, `WalletScreen`, `TransactionHistoryScreen`, `DisputeScreen`, `ReconciliationScreen`, `EquipmentAddScreen`.

**9 écrans réellement réécrits**, branchés sur leurs providers existants plutôt que sur des coquilles :
- Réservation : `ReservationConfirmationScreen`, `ReservationQRScreen`, `ReservationHistoryScreen`, `PharmacyQueueScreen`.
- Livraison : `DeliveryHistoryScreen`, `DeliveryScheduleScreen` (avec affectation chauffeur).
- Administration : `PharmaciesManagementScreen`, `AuditLogScreen`, `SystemConfigScreen`.

**Non fait, limite honnête à noter :** la vérification interactive complète en navigateur (Playwright) n'a pas pu être menée à terme — captures blanches répétées malgré des attentes généreuses, probablement dues au délai de compilation Flutter web en mode debug combiné à la redirection d'authentification systématique vers `/login`. Les écrans ont été vérifiés par lecture de code et `flutter analyze`/`flutter test`, pas par clic réel dans un navigateur.

Trouvé séparément le 27/08/2026 (lors de la préparation des tests, §5.5 de `REFERENTIEL_ARCHITECTE.md`) : un 18ème écran placeholder, hors de la liste des 17 initiaux, restait non traité — `PlaceholderScreen(title: 'Détail de la transaction #$id')` sur `/transactions/:id`. Résolu depuis, voir la mise à jour « dernier écran placeholder implémenté » en tête de fichier.

## Mise à jour (26/08/2026) — saisie téléphone séparée en composant dédié, dépôt git initialisé

Deux fichiers ajoutés dans le module `auth` : `lib/modules/auth/models/phone_country.dart` (liste `PhoneCountry`, un seul pays actif aujourd'hui — Guinée, `+224`, 9 chiffres locaux — extensible sans réécriture quand le GSG Referential sera branché) et `lib/modules/auth/widgets/phone_input_field.dart` (sélecteur pays + champ numérique local, formatters chiffres uniquement, suppression du `0` initial). `login_screen.dart` et `register_screen.dart` affichent désormais `PhoneInputField` à la place du champ identifiant générique quand la méthode SMS/WhatsApp est sélectionnée ; le champ générique reste utilisé pour l'email. La normalisation E.164 finale continue de passer par `Validators.normalizeE164()` (`lib/core/utils/validators.dart`) — un point unique qui existait déjà avant ce changement (voir correction de trace historique en §3.2 de `REFERENTIEL_ARCHITECTE.md`) ; le nouveau widget alimente ce même point plutôt que de dupliquer la normalisation.

Par ailleurs, le dépôt a été initialisé en git ce même jour (`git init` + premier commit honnête reflétant l'état vérifié du code, pas une affirmation non vérifiée) — voir `git log` pour l'historique à jour. C'est ce qui permet désormais de suivre ce type de changement comme un diff isolé plutôt que comme une modification silencieuse d'un état déjà flou.

Un remote GitHub a ensuite été configuré (`https://github.com/TamataDelamou/pharma_connect-`, privé) et la branche locale renommée `master` → `main` pour correspondre au déclencheur du workflow. Premier push effectué — première exécution réelle de `.github/workflows/kernel-compliance.yml` depuis sa création. Ce premier run a immédiatement révélé deux problèmes invisibles en local : `assets/icons/`/`assets/images/` déclarés dans `pubspec.yaml` mais jamais suivis par git (dossiers vides — corrigé avec des `.gitkeep`), et `flutter analyze` qui échoue par défaut sur les avertissements *et* les infos, pas seulement les erreurs (jamais vérifié jusqu'ici : seul le nombre d'erreurs était contrôlé, jamais le code de sortie réel de la commande). 25 imports/champs/variables réellement inutilisés nettoyés dans 22 fichiers, et `--no-fatal-infos` ajouté à l'étape `flutter analyze` du workflow pour aligner le seuil CI sur celui visé depuis le début du projet (0 erreur, avertissements/infos non bloquants). Second push : **CI verte** — les trois garde-fous KER-* s'exécutent réellement pour la première fois.

## Mise à jour (27/08/2026, suite) — premières migrations Supabase écrites

`supabase/migrations/` (vide depuis l'origine, sur les cinq audits précédents) contient désormais 15 fichiers, un schéma complet pour les 14 modules ayant du code réel côté Dart : `profiles` (extension de `auth.users`), `catalog` (categories/manufacturers/products), `pharmacies`/`pharmacy_groups` (table canonique unique — voir plus bas), `admin` (admin_users/audit_logs/system_configs), `stock` (stock_items/stock_batches/stock_movements/stock_adjustments), `traceability` (traceable_batches/batch_movements/cold_chain_records/certificates/verification_scans), `coldchain`, `recall`, `prescriptions`, `reservations`, `delivery` (drivers/deliveries/proofs/routes/stops), `payments` (transactions/installments/wallets/invoices), `alerts`, et `search` (search_history seulement — les résultats de recherche eux-mêmes sont calculés à la volée, pas persistés).

Trois décisions structurantes prises en écrivant ce schéma, à connaître avant d'y toucher :

1. **Une seule table `pharmacies` canonique**, pas trois. Le code Dart modélise la même entité réelle (une officine) sous trois formes différentes selon le module — `AdminPharmacy` (admin, gestion DNPM), `Pharmacy` (search, vue publique) et `PharmacyBranch` (stock, notion de succursale). Dupliquer ça en trois tables aurait rendu impossible de savoir laquelle fait foi. `pharmacies` reprend le sur-ensemble de champs d'`AdminPharmacy` ; chaque service peut continuer à n'exposer qu'un sous-ensemble de colonnes côté Dart sans que le schéma soit redondant.
2. **Deux écarts comblés que les modèles Dart ne couvraient pas** : `stock_items.pharmacy_id` (le modèle `StockItem` actuel n'a qu'un `defaultLocation` texte libre — un stock persisté doit pourtant être scopé par officine, sinon Multi-officines n'a pas de fondation) et `stock_items.unit_price` (aucun modèle Dart ne porte le prix de vente ; `PharmacyStock.price` côté `search` est aujourd'hui une valeur mockée, sans source persistée). Les deux sont documentés en commentaire SQL dans `20260827000600_stock.sql`.
3. **RLS activée sur les 33 tables**, mais volontairement inégale : les tables de référentiel/catalogue (`products`, `pharmacies`, `categories`...) sont en lecture ouverte à tout utilisateur authentifié ; les données personnelles (`profiles`, `wallets`, `alerts`, `prescriptions`, `reservations`, `transactions`, `deliveries`...) sont limitées à leur propriétaire (`auth.uid()`) en lecture, sans politique d'écriture pour l'instant. L'accès « staff » (un pharmacien voit la file d'attente de son officine, un livreur voit sa tournée — cf. `pharmacy_queue_screen.dart` ajouté le 27/08) n'est **pas** couvert : ça suppose un mécanisme de vérification de rôle/rattachement utilisateur ↔ officine qui n'existe pas encore côté produit. L'inventer dans cette migration aurait été une hypothèse de conception, pas un exercice mécanique — laissé comme chantier séparé, documenté en commentaire dans chaque fichier concerné.

En écrivant ces migrations, `scripts/ci/check_no_cross_schema_fk.sh` s'est révélé cassé depuis sa création (vérifiait le mauvais côté du point dans `references schema.table`, rejetait même `auth.users`) — invisible tant qu'aucune vraie migration n'existait pour l'exercer. Corrigé, revérifié dans les deux sens. Détail → `REFERENTIEL_ARCHITECTE.md` §5.6.

Vérifié : les 15 fichiers parsent sans erreur avec un vrai analyseur SQL PostgreSQL (`libpg-query`, hors dépendances du projet, aucun outil Docker/`supabase` CLI disponible dans cet environnement pour un `supabase db reset` réel) ; toutes les FK pointent vers une table déjà créée au moment où elle est référencée (vérifié par script) ; aucun nom de table/index/politique dupliqué ; les trois garde-fous CI passent.

**Non fait, à faire séparément :** provisionner un vrai projet Supabase et renseigner `supabase_service.dart` (actuellement `https://votre-projet.supabase.co` / `votre-clé-anon`) — ça ne se fait pas depuis un dépôt de code, ça nécessite un compte/dashboard Supabase. Câbler les services Dart mockés (`*_service.dart`) sur ce schéma reste également un chantier à part : cette migration donne un schéma cible, elle ne branche rien côté client.

## Mise à jour (27/08/2026) — gestion d'erreur des providers unifiée, montants int déjà conformes

**Montants (KER-REF-05, `REFERENTIEL_ARCHITECTE.md` §3.1) :** vérification directe du code — `Transaction.amount/fee/cashback/finalAmount`, `Installment.totalAmount/amountPerPayment`, `InstallmentPayment.amount`, `Reservation.totalPrice`, `ReservationItem.pricePerUnit`, `PaymentProvider._walletBalance` sont déjà tous en `int`, aucun `double` monétaire nulle part dans `lib/`. Rien à corriger ; §3.1 mis à jour avec une note « Résolu » pour ne plus lister ce point comme un chantier ouvert (même écart de gouvernance que §3.2 : le code avait progressé sans que la doc suive).

**Gestion d'erreur des providers (`REFERENTIEL_ARCHITECTE.md` §3.3) :** `prescription_provider.dart` et `reservation_provider.dart` n'avalent déjà plus aucune erreur silencieusement — constat également obsolète. Seul `search_provider.dart` avait un vrai reliquat, plus étendu que documenté (4 `catch` silencieux, dont un littéral `// ignore` dans `clearHistory` — pas 2) : corrigé, alignés sur `_error = e.toString(); notifyListeners();`.

Le symptôme réellement visible pour l'utilisateur n'était pas là où `REFERENTIEL_ARCHITECTE.md` le pointait, mais un cran plus loin : l'état `_error` du provider existait souvent mais n'était **jamais lu par l'écran**. Trouvé et corrigé : `prescription_detail_screen.dart` restait bloqué sur un spinner **infini** si `loadPrescription()` échouait (jamais de sortie de l'état de chargement) ; `prescription_list_screen.dart` et `patient_history_screen.dart` affichaient « Aucune ordonnance » sur un échec réseau, indiscernable d'une vraie liste vide ; `reservation_checkout_screen.dart` affichait un message d'erreur générique codé en dur au lieu de `provider.error`. Les quatre écrans suivent désormais le patron déjà en usage dans `catalog_list_screen.dart`/`stock_list_screen.dart` (état erreur dédié, bouton Réessayer, avant l'état vide).

## Mise à jour (26/08/2026) — régression KER-DES-03/KER-REF du 25/08 vérifiée déjà résolue, nouvel écart de même famille corrigé

Avant de traiter l'élément 1 de « Chantiers ouverts » (18 couleurs + 11 chaînes GNF codées en dur, régression du 25/08 documentée juste en dessous), vérification directe du code plutôt que de la liste : les deux garde-fous CI (`check_no_hardcoded_color.sh`, `check_no_hardcoded_currency.sh`) passent déjà au vert, et lecture de `batch_status.dart`/`traceable_batch.dart` confirme que les deux getters `color`/`statusColor` retournent déjà des constantes `PharmaConnectColors`. Cette régression a en réalité été corrigée en marge de la reconstruction de `traceable_batch.dart` documentée dans `code_export_architecte.md` (rapport du 26/08) — la liste « Chantiers ouverts » de ce fichier n'avait simplement pas été mise à jour en conséquence. Corrigé ci-dessous (§ Chantiers ouverts).

Ce même rapport du 26/08 signalait cependant un écart réel et distinct, non couvert par la CI actuelle : 10 fichiers modèles (`alert.dart`, `admin_pharmacy.dart`, `temperature_record.dart`, `cold_equipment.dart`, `cold_incident.dart`, `verification_result.dart`, `recall_status.dart`, `recall.dart`, `recall_affected_batch.dart`, `stock_movement.dart`) utilisaient des couleurs Material **nommées** littérales (`Colors.red`, `Colors.orange`, `Colors.blue`, `Colors.grey`, `Colors.yellow`, `Colors.purple`, `Colors.cyan`...) au lieu des tokens `PharmaConnectColors` — le même anti-motif KER-DES-03 sous une forme que `check_no_hardcoded_color.sh` ne détectait pas (il ne cherchait que `Color(0xFF...)` littéral). Corrigé : les 47 occurrences remplacées par les tokens existants selon la correspondance déjà en usage ailleurs dans le code (`Colors.red` → `accentRed`, `Colors.orange` → `accentOrange`, `Colors.green` → `accentGreen`, `Colors.blue`/`Colors.cyan` → `accentCyan`, `Colors.yellow` → `accentAmber`, `Colors.grey` → `neutralMuted`, `Colors.purple` → `accentPurple`), aucun nouveau token créé.

`check_no_hardcoded_color.sh` a ensuite été étendu le même jour pour détecter cette forme : en plus du `Color(0xFF...)` littéral (recherché dans tout `lib/`, comme avant), il recherche désormais `Colors.<nom>` sémantique (`red`, `orange`, `green`, `blue`, `purple`, `yellow`, `amber`, `cyan`, `grey`...) dans `lib/modules/*/models/` — le seul gabarit où la régression s'est répétée deux fois (18 occurrences le 25/08, 47 le 26/08). `Colors.white`/`black`/`transparent` restent volontairement exclus (structurels — glass effects, overlays — pas de portée de marque, 204 usages légitimes répartis sur 76 fichiers) et la détection reste volontairement bornée à `*/models/` plutôt qu'à tout `lib/` : étendre à tout `lib/` (écrans, widgets) sans revue humaine préalable produirait des dizaines de faux positifs sur du code déjà accepté. Vérifié positivement (silencieux sur le code actuel, les 10 modèles corrigés compris) et négativement (échoue bien face à une régression `Colors.red`/`Colors.red[700]` injectée délibérément dans un modèle, puis retirée).

## Mise à jour (25/08/2026) — régression non documentée détectée et corrigée

**Constat, avant toute nouvelle lecture de ce fichier :** entre le 24/08 (état décrit ci-dessous) et le 25/08, six nouveaux modules ont été codés (`stock`, `traceability`, `coldchain`, `recall`, `admin`, `alerts` — 86 fichiers Dart) **sans que ce fichier, ni `REFERENTIEL_ARCHITECTE.md`, ni `code_export_architecte.md` ne soient mis à jour**. Dans l'intervalle, `pubspec.yaml` a été cassé (trois dépendances dupliquées — YAML invalide, `flutter pub get` levait une exception avant même d'atteindre l'analyseur) et une dépendance non maintenue (`tesseract_ocr`, incompatible null-safety) a été ajoutée pour l'OCR des ordonnances. Résultat : le dépôt était dans un état où **aucune commande Flutter ne pouvait s'exécuter**, alors que ce fichier affirmait toujours « `flutter analyze` : aucun signalement ». Cette affirmation ne pouvait matériellement pas avoir été vérifiée sur le code réellement présent dans le dépôt au moment de la lecture — voir `code_export_architecte.md`, section « Rapport d'audit — 25 août 2026 » pour le détail complet et l'hypothèse la plus probable (absence de dépôt git, donc aucune trace de ce qui s'est passé entre les deux dates).

Deux régressions concrètes, plus graves qu'un simple retard de documentation, ont été trouvées dans ce nouveau code :

1. **KER-DES-03 (couleurs codées en dur)** — le module `traceability`, ajouté après que cette règle a été formalisée et après que l'écart équivalent a été corrigé dans 5 autres modèles (voir plus bas), reproduit exactement le même anti-motif : 18 occurrences de `Color(0xFF...)` littéral dans `batch_status.dart` et `traceable_batch.dart`. Le garde-fou CI `check_no_hardcoded_color.sh` existait déjà et aurait dû l'empêcher — il ne s'est simplement jamais exécuté, faute de dépôt git pour déclencher `.github/workflows/kernel-compliance.yml`.
2. **KER-REF (devise codée en dur)** — 11 occurrences de `'... GNF'` littéral trouvées le 25/08, dont plusieurs dans `payments/` — un module pourtant documenté ci-dessous comme déjà mis en conformité le 24/08. Soit la conformité n'a pas été aussi complète que documenté, soit une régression a eu lieu depuis ; sans git, impossible de trancher.

**Non corrigé dans l'immédiat** (nécessite un arbitrage visuel/produit, pas une substitution mécanique) : le remplacement des 18 + 11 littéraux par les tokens/`CurrencyFormatter` corrects. Voir `REFERENTIEL_ARCHITECTE.md` §3.5 pour le détail et la marche à suivre.

Ce qui a été corrigé le 25/08 pour que le projet compile à nouveau : `pubspec.yaml` réparé, `tesseract_ocr` remplacé par `google_mlkit_text_recognition`, et 216 erreurs de compilation résorbées à travers 54 fichiers (imports manquants, un membre d'enum nommé `return` — mot réservé Dart —, des signatures désynchronisées entre providers et services, 8 fichiers référencés par le routeur ou par `search_screen.dart` mais jamais créés). Détail complet → `code_export_architecte.md`, section « Rapport d'audit — 25 août 2026 ». `flutter analyze` : 0 erreur, 83 avertissements/infos non bloquants. `flutter test` : 1/1.

## État du projet (24/08/2026)

Le projet est **en chantier**, pas au stade zéro décrit par le cahier de conception initial. Section conservée telle qu'écrite le 24/08 pour l'historique ; **le décompte de modules ci-dessous est dépassé**, voir le tableau à jour juste après :

- `flutter analyze` : aucun signalement (« No issues found! »).
- `flutter test` : 1 test, 0 échec — un seul test de démarrage protège toute l'application ; `test/unit/` et `test/widget/` existent mais sont **vides**.
- 8 modules sur 34 avaient du code réel à cette date : **auth, dashboard, search, catalog, prescriptions, reservations, delivery, payments**.

### Tableau à jour (25/08/2026)

| | |
|---|---|
| Modules avec code réel | 14 / 33 dossiers existants : `search` (22 fichiers), `stock` (17), `reservations` (17), `payments` (17), `prescriptions` (16), `delivery` (15), `traceability` (14), `recall` (14), `coldchain` (14), `admin` (14), `alerts` (11), `catalog` (10), `auth` (8), `dashboard` (7) |
| Modules vides | 19 dossiers présents mais sans code (`analytics`, `business`, `chains`, `family`, `financing`, `forecasting`, `healthrecord`, `homecare`, `hospitals`, `insurance`, `iot`, `loyalty`, `marketplace`, `professionals`, `regulator`, `solidarity`, `support`, `teleconsult`, `triage`) + `eprescription`, cité dans le cahier de conception racine mais dont **le dossier n'existe même pas encore** dans `lib/modules/` |
| `flutter analyze` | 0 erreur, 83 avertissements/infos (voir §CI plus bas) |
| CI | **Verte** depuis le 26/08/2026 (remote GitHub configuré, premier push) — voir §CI plus bas pour le détail |
- `catalog` et `search` sont deux modules **distincts et complémentaires**, pas redondants : `catalog` liste les produits et leur classification (catégories, fabricants) via le modèle partagé `Product` (`lib/shared/models/product.dart`) — aucune notion de prix ni de stock. `search` réutilise les mêmes produits mais y ajoute la disponibilité en officine et le prix (`AvailabilityResult`). Les prix et les stocks réels resteront portés par `search` et par le futur module `stock` (FEFO) — ne pas faire porter cette responsabilité à `catalog`.
- Intégration de `catalog` finalisée (24/08/2026) : `CatalogProvider` était utilisé (`context.watch`/`context.read`) par `catalog_list_screen.dart` et `catalog_detail_screen.dart` sans jamais être enregistré dans le `MultiProvider` de `lib/app.dart` — corrigé (`ProviderNotFoundException` évitée). Le module a aussi été raccordé à la navigation : le `SidebarNavigation` du tableau de bord n'appelait jamais `context.go(route)` (seul le surlignage local changeait, aucun module — y compris `catalog` — n'était réellement atteignable au clic) ; corrigé dans `dashboard_screen.dart`, et une entrée « Catalogue » → `/catalog` a été ajoutée à la barre latérale.
- 13 écrans du routeur sont des **coquilles provisoires** (`core/widgets/screens/placeholder_screen.dart`), pas de vraie UI/logique métier : `ReservationCheckoutScreen`, `ReservationConfirmationScreen`, `ReservationQRScreen`, `ReservationHistoryScreen`, `PharmacyQueueScreen`, `DeliveryHistoryScreen`, `DeliveryScheduleScreen`, `DriverDashboardScreen`, `InstallmentPlanScreen`, `WalletScreen`, `TransactionHistoryScreen`, `DisputeScreen`, `ReconciliationScreen`.
- **Aucune migration Supabase** n'existe encore (`supabase/migrations/` est vide) : le schéma de données n'existe aujourd'hui que côté client, sous forme de classes Dart (`Delivery`, `Reservation`, `Transaction`, `Prescription`...). Rien n'est encore persisté côté serveur.
- `SupabaseService` (`lib/core/services/supabase_service.dart`) pointe vers des valeurs placeholder (`https://votre-projet.supabase.co`, `votre-clé-anon`) — à renseigner avant tout test contre un vrai projet Supabase (local via `supabase start`, ou distant).
- `GsgKernelAuthBridge` (`lib/core/kernel/gsg_kernel_auth_bridge.dart`) pointe vers `https://kernel.gsg.example` — le Kernel n'est pas encore déployé ; l'app tourne aujourd'hui « en mode dégradé » avec Supabase Auth seul (voir plus bas).
- 27 paquets ont des versions plus récentes disponibles (`flutter pub outdated`) — mise à jour volontairement différée pour ne pas introduire de régression hors périmètre.

Historique détaillé de la dernière intervention (imports manquants, enums fantômes, écrans du routeur jamais écrits, bug de type sur `getWalletBalance()`, `.withOpacity()` déprécié...) : voir `code_export_architecte.md`, section « Rapport d'audit — 24 août 2026 ».

## Stack réelle (pubspec.yaml / package.json)

- **Flutter** (SDK ^3.12.0), Material.
- État : **provider** (`ChangeNotifier` par module, enregistrés dans `lib/app.dart`) + **equatable**.
- Routing : **go_router**, une seule table de routes centralisée dans `lib/routes/app_router.dart`, avec redirection auth-aware (`isAuthenticated` → `/dashboard`, sinon → `/login`).
- Backend : **supabase_flutter ^2.0.0** (Auth, et à terme Postgres/Storage/Realtime).
- Réseau hors-Supabase : **dio** (utilisé notamment par `GsgKernelAuthBridge`).
- Stockage local : **shared_preferences**, **sqflite**.
- Connectivité : **connectivity_plus**.
- Scan/caméra : **mobile_scanner**, **image_picker** (ordonnances, QR retrait).
- Notifications : **flutter_local_notifications**.
- CLI Supabase : gérée via npm (`package.json` → `npm run supabase ...`), config locale dans `supabase/config.toml` (`project_id = pharma_connect`, ports par défaut du CLI Supabase).
- CI : GitHub Actions, workflow unique `.github/workflows/kernel-compliance.yml` (voir plus bas).

## Structure du dépôt

```
lib/
  core/
    kernel/      → pont vers le GSG Kernel (auth bridge, statut, badge, indicateur de connexion)
    services/    → SupabaseService (singleton client Supabase)
    theme/       → design system local (couleurs, glass, spacing, typographie, animations)
    utils/       → CurrencyFormatter, validators (vide), extensions (vide)
    widgets/     → composants partagés (boutons, cards, inputs, modals, navigation, placeholder_screen)
  modules/       → un dossier par module métier du cahier de conception (models/providers/screens/services/widgets)
  routes/        → app_router.dart, table de routes go_router unique
  app.dart       → MultiProvider + MaterialApp.router
  main.dart      → point d'entrée, initialise Supabase avant runApp
supabase/
  config.toml    → config CLI Supabase locale
  migrations/    → vide à ce jour
scripts/ci/      → garde-fous KER-* exécutés en CI (bash)
test/            → widget_test.dart (1 test) ; unit/ et widget/ vides
```

## Authentification — implémentation actuelle

Conforme au *Modèle d'authentification Supabase* : choix de l'identifiant (téléphone ou email) puis du canal de réception, sans réimplémenter ce que Supabase Auth fait nativement.

- `lib/modules/auth/services/auth_service.dart` — `sendPhoneOtp(phone, channel: 'sms'|'whatsapp')` / `verifyPhoneOtp()`, `sendMagicLink()` / `sendEmailOtp()` / `verifyEmailOtp()`. Fine couche au-dessus de `GoTrueClient` (`signInWithOtp` / `verifyOTP`), rien d'autre.
- `lib/modules/auth/providers/auth_provider.dart` — état d'authentification exposé à l'UI (`ChangeNotifier`), déclenche le pont Kernel après un `verifyOTP()` réussi.
- `lib/core/kernel/gsg_kernel_auth_bridge.dart` — échange la session Supabase contre une identité GSG ID (`POST /v1/auth/sso/supabase`). **Best-effort, non bloquant** : toute erreur réseau ou timeout (5s) renvoie `null` sans lever d'exception ; le login reste valide avec la seule session Supabase si le Kernel est injoignable.
- `lib/modules/auth/widgets/phone_input_field.dart` — saisie téléphone séparée en sélecteur pays (`lib/modules/auth/models/phone_country.dart`) + champ numérique local, normalisée en E.164 via `Validators.normalizeE164()` avant d'être transmise à `AuthProvider.sendPhoneOtp()`. Utilisé par `login_screen.dart` et `register_screen.dart` quand la méthode SMS/WhatsApp est sélectionnée.
- Écrans : `login_screen.dart`, `register_screen.dart`, `otp_verification_screen.dart`.

## Règles d'architecture — conformité GSG Kernel v3.0

Ces règles découlent de l'audit de conformité Kernel du 24/08/2026 (voir `code_export_architecte.md`). Elles s'appliquent à tout nouveau code touchant à la persistance ou à l'identité, pas seulement au code déjà audité.

### Schéma de données — clés primaires locales (KER-VIS-01, KER-ORG-02)

Toute nouvelle table métier locale (`pharmacies`, `reservations`, `deliveries`, `transactions`, etc.) **conserve sa propre clé primaire locale** (`id`, uuid généré localement) comme identifiant canonique du produit.

- `gsg_id` et `gsg_org_id` ne sont **jamais** la clé primaire. Ce sont des colonnes scalaires optionnelles (`nullable`), ajoutées en plus de `id`, qui font simplement le lien vers le Kernel quand il est connu.
- Aucune refonte destructive d'une table existante pour la faire correspondre au schéma du Kernel n'est acceptable — ni migration qui remplace `id` par `gsg_id`, ni suppression de la PK locale.

### Étanchéité de la base (KER-VIS-03)

Zéro `FOREIGN KEY` / `REFERENCES` SQL pointant vers une table hors du schéma `public`/`auth` du projet. Le lien vers le Kernel se fait uniquement par scalaire (uuid/string) + appel API, jamais par contrainte SQL inter-bases. Garde-fou CI : `scripts/ci/check_no_cross_schema_fk.sh` (grep sur `supabase/migrations/*.sql`, schémas autorisés : `public|auth|storage|extensions|graphql_public`).

### Authentification (KER-ID-02)

Le SDK Supabase Auth natif (`signInWithOtp` / `verifyOTP`) reste l'unique mécanisme qui authentifie l'utilisateur — voir `auth_service.dart`. Tout code de génération de code OTP, ou wrapper direct vers un provider SMS/WhatsApp/email dans ce dépôt, est une régression : le produit ne doit jamais réimplémenter ce que Supabase Auth fait déjà nativement.

L'échange vers le GSG ID se fait *après* un `verifyOTP()` réussi, via `gsg_kernel_auth_bridge.dart` — jamais avant, et jamais de façon bloquante pour le login.

### Devise & référentiel (KER-REF)

Tout affichage de montant passe par `CurrencyFormatter` (`lib/core/utils/currency_formatter.dart`). Aucune chaîne de devise (« GNF », « FCFA », ...) codée en dur dans un widget. Devise par défaut câblée en dur (GNF, ISO 4217 324) tant que le produit ne gère qu'un seul marché ; à faire venir du GSG Referential résolu pour l'organisation courante quand le Kernel sera branché. Garde-fou CI : `scripts/ci/check_no_hardcoded_currency.sh`.

### Résilience (KER-ARC-03)

Tout appel réseau vers un service du Kernel (statut, référentiel, SSO...) passe par un adaptateur qui échoue en silence (retourne `null`/un état dégradé) plutôt que de lever une exception qui bloquerait un cas d'usage métier. Voir `gsg_kernel_auth_bridge.dart` pour le patron à suivre. Ne jamais coder en dur un statut « connecté » ou « online » dans l'UI sans qu'un appel réel ne l'alimente.

### Design System — contrat de tokens (KER-DES-03)

Brique non urgente (KER-DES-02) : PharmaConnect n'adopte pas encore le GSG Design Kit et ce n'est pas un blocage. Mais le futur Kit n'exposera que des tokens sémantiques (couleur primaire, accent succès, surface, texte secondaire...) — jamais de couleur codée en dur dans un composant partagé — et chaque produit branchera sa propre palette sur ce contrat. `lib/core/theme/colors.dart` (`PharmaConnectColors.accentGreen`, `accentOrange`, `accentAmber`, `accentRed`, `neutralMuted`, `textPrimary`, `textSecondary`...) est écrit dans cet esprit : des rôles nommés, pas des composants qui lisent des hex en dur. Le jour où le Kit existera, ce fichier deviendra directement l'implémentation locale du contrat de tokens attendu, sans réécriture des écrans qui le consomment déjà.

Cette discipline a été contournée dans 5 modèles de statut (`delivery.dart`, `transaction.dart`, `prescription.dart`, `reservation.dart`, `availability_result.dart`), dont les getters `statusColor`/`stockColor` retournaient un `Color(0xFF...)` littéral au lieu d'une constante `PharmaConnectColors` — 27 occurrences, le même gabarit copié-collé à chaque fois. Corrigé : deux tokens manquants ajoutés (`neutralMuted`, `accentAmber`), les 27 littéraux remplacés, garde-fou CI `scripts/ci/check_no_hardcoded_color.sh` ajouté pour empêcher toute régression. Détail complet → `REFERENTIEL_ARCHITECTE.md`. Éviter en particulier d'introduire une couleur littérale nouvelle directement dans un modèle ou un widget de module (`modules/*/models`, `modules/*/screens`, `modules/*/widgets`) : passer par `PharmaConnectColors` (ou son équivalent futur) comme on le fait désormais partout.

## CI

`.github/workflows/kernel-compliance.yml`, se déclenche sur push vers `main` et sur toute pull request :

1. `scripts/ci/check_no_cross_schema_fk.sh` (KER-VIS-03)
2. `scripts/ci/check_no_hardcoded_currency.sh` (KER-REF)
3. `scripts/ci/check_no_hardcoded_color.sh` (KER-DES-03)
4. `flutter pub get`
5. `flutter analyze --no-fatal-infos`

Toute contribution doit passer ces cinq étapes avant merge — **et depuis le 26/08/2026, ce n'est plus théorique**. Un remote GitHub a été configuré (dépôt privé) et le workflow s'est réellement exécuté pour la première fois. Le premier run a échoué (assets déclarés mais non suivis par git, `flutter analyze` par défaut plus strict que le seuil visé par le projet — voir la mise à jour du 26/08/2026 en tête de fichier pour le détail) ; corrigé, second run **vert**. C'est très concrètement ce qui aurait empêché les deux régressions du 25/08 (§ plus haut) : les garde-fous étaient écrits, corrects, mais inertes faute de dépôt git pour les déclencher — ce n'est plus le cas.

## Commandes utiles

```bash
flutter pub get                 # dépendances
flutter analyze --no-fatal-infos # lint/typecheck — doit rester à 0 erreur/avertissement (commande utilisée par la CI)
flutter test                    # suite de tests — actuellement 1 seul test
flutter run                     # lancer l'app (nécessite un vrai projet Supabase configuré)

npm run supabase -- start       # démarrer Supabase en local (CLI, config supabase/config.toml)
npm run supabase -- db diff     # générer une migration à partir du schéma local
bash scripts/ci/check_no_cross_schema_fk.sh      # garde-fou KER-VIS-03 en local
bash scripts/ci/check_no_hardcoded_currency.sh   # garde-fou KER-REF en local
bash scripts/ci/check_no_hardcoded_color.sh      # garde-fou KER-DES-03 en local
```

## Chantiers ouverts (par ordre de dépendance)

0. ~~Initialiser un dépôt git~~ — **fait le 26/08/2026** : dépôt git initialisé, remote GitHub configuré, CI vérifiée verte. Ne reste plus dans cette liste que par cohérence avec la numérotation historique.
~~1. Corriger les deux régressions de gouvernance du 25/08~~ — **vérifié déjà résolu le 26/08/2026** (les deux garde-fous CI passent, code relu). Voir la mise à jour du 26/08/2026 en tête de fichier. Écart de même famille trouvé et corrigé dans la foulée : 10 fichiers modèles avec couleurs Material nommées littérales, non couvert par la CI actuelle (§ même mise à jour).
~~2a. Écrire les premières migrations dans `supabase/migrations/`~~ — **fait le 27/08/2026** : 15 fichiers, schéma complet des 14 modules (KER-VIS-01 : PK locale + `gsg_id`/`gsg_org_id` nullables sur `profiles`/`pharmacies`). Voir la mise à jour du 27/08/2026 en tête de fichier pour le détail et les décisions de conception prises.

~~2c. Câbler les services Dart mockés sur le schéma~~ — **fait le 27/08/2026** sur `feature/supabase-backend` : les 12 services encore mockés (`catalog`, `alerts`, `admin`, `coldchain`, `recall`, `traceability`, `stock`, `delivery`, `payments`, `prescriptions`, `reservations`, `search`) utilisent désormais `Supabase.instance.client` avec CRUD réel, signatures publiques inchangées. Voir la mise à jour du 27/08/2026 (« P0 ») en tête de fichier pour le détail complet et les limites connues.

~~2b. Configurer un vrai projet Supabase~~ — **fait le 27/08/2026** : projet distant `qemizapoldevapmygryp.supabase.co` créé par l'utilisateur, `supabase_service.dart` branché sur ses vraies URL/clé, les 15 migrations poussées via `npx supabase db push --linked` et confirmées appliquées (`migration list` : local = remote sur les 15). Voir la mise à jour du 27/08/2026 (« 2b ») en tête de fichier. Les 18 tests qui pointent volontairement sur un projet factice (`example.supabase.co`) dans leur `setUpAll` restent rouges par construction — pas un chantier lié à 2b, c'est le comportement voulu de ces tests.
~~2d. Charger des données de départ~~ — **fait le 27/08/2026** : `supabase/seed.sql` charge le catalogue (6 catégories, 5 fabricants, 20 médicaments), 6 officines de Conakry et le stock croisé (120 `stock_items`/`stock_batches`). Voir la mise à jour du 27/08/2026 (« données de départ ») en tête de fichier. Les tables à portée personnelle (profiles, wallets, prescriptions...) restent volontairement vides — pas de compte `auth.users` réel à qui les rattacher.
~~3. Implémenter les écrans placeholder~~ — **fait le 27/08/2026** : 8 des 17 s'avèrent déjà réels à l'audit, 9 réécrits, plus le 18ème trouvé hors de la liste initiale (`TransactionDetailScreen` sur `/transactions/:id`, branché sur `PaymentProvider.loadTransaction()` déjà existant). Voir les mises à jour du 27/08/2026 en tête de fichier. Aucun écran placeholder ne reste dans le routeur.
~~4. Étoffer la couverture de tests~~ — **fait le 27/08/2026** sur `test/expand-coverage` : 27 tests unitaires (`test/unit/providers/`, 14/14 providers) + 14 tests widget (`test/widget/screens/`, un par écran principal de module). A aussi trouvé et corrigé un vrai bug (6 providers jamais enregistrés dans `app.dart`, `ProviderNotFoundException` garantie sur 20 écrans) et 2 bugs dans `recall_dashboard_screen.dart` (overflow + erreur de type sur un graphique). Voir la mise à jour du 27/08/2026 en tête de fichier. Reste ouvert : les écrans secondaires (détail/formulaires) et les 20 modules non entamés restent hors périmètre.
5. **Démarrer les 20 modules non entamés** du cahier de conception (marketplace B2B, HomeCare, dossier de santé numérique, etc. — `stock`, `traceability`, `recall`, `coldchain`, `admin`, `alerts` sont sortis de cette liste le 25/08) — se référer à la section « Module N » correspondante du *Cahier de Conception PharmaConnect v2.1* pour l'objectif, les règles de gestion et les écrans attendus de chacun avant de créer le code, et à `REFERENTIEL_ARCHITECTE.md` §4.2 pour la checklist Kernel à remplir avant d'écrire le premier fichier — celle qui, manifestement, n'a pas été suivie pour les 6 modules ajoutés le 25/08.
6. **Brancher le GSG Kernel réel** une fois son URL de production connue (`gsg_kernel_auth_bridge.dart` a un `TODO(kernel-integration)` explicite) — sans casser le mode dégradé existant.
~~7. Mise à jour des paquets obsolètes~~ — **fait le 27/08/2026** sur `chore/update-outdated-packages`, **fusionnée dans `main` le 27/08/2026** : les 16 dépendances directes sont à jour, dont `go_router` (13→18), `mobile_scanner` (3.5→7.4), `geolocator` (11→14). Voir la mise à jour du 27/08/2026 en tête de fichier pour le détail des 2 fichiers cassés par la montée de version et leur correction.
~~8. Fusionner les 4 branches en attente~~ — **fait le 27/08/2026** : `feature/supabase-backend` (superset de `test/expand-coverage`) puis `chore/update-outdated-packages` fusionnées dans `main`, un seul conflit (ce fichier, résolu en conservant le contenu le plus détaillé des deux côtés). Voir la mise à jour « fusion des 4 branches » en tête de fichier. Les branches elles-mêmes n'ont pas été supprimées.
~~9. Étendre les politiques RLS d'écriture par rôle (P1)~~ — **fait le 27/08/2026** sur `feature/staff-rls-write-policies` : `profiles.role`/`profiles.pharmacy_id` + 10 nouvelles politiques d'écriture staff officine/livreur. A aussi trouvé et corrigé un vrai bug (`profiles` jamais écrite par le produit, voir `REFERENTIEL_ARCHITECTE.md` §2 point 18). Voir la mise à jour du 27/08/2026 (« P1 ») en tête de fichier. **Reste ouvert** : aucune UI pour assigner `pharmacy_id`/enregistrer un `delivery_drivers` (flux post-vérification de licence) — sans ça, les nouvelles policies restent correctes mais inatteignables depuis l'app tant qu'un profil staff n'a pas son `pharmacy_id` renseigné manuellement (ex. via le SQL editor Supabase, en attendant ce flux).
10. **Tester end-to-end contre le vrai backend** via un compte créé par le vrai flux d'inscription (pas un seed SQL) — réservation/paiement/ordonnance n'ont jamais été exercés contre le projet Supabase réel. **Tenté le 27/08/2026, bloqué** : SMS/WhatsApp indisponible sur le projet (`external_phone_enabled: false`), et l'inscription par email ne délivre qu'un lien (pas de code) faute de pouvoir personnaliser le template email sur le plan gratuit Supabase avec expéditeur par défaut — voir la mise à jour du 27/08/2026 (« P1 (fin) ») en tête de fichier. Décision : reporté, pas de SMTP tiers ni d'upgrade Supabase pour l'instant. À reprendre en configurant un SMTP tiers ou en upgradant le plan.

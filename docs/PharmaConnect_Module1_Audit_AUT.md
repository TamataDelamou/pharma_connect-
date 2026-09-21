# Module 1 — AUT (Authentification & Comptes multi-profils) : rapport de clôture

**Date de l'audit :** 29/08/2026
**Périmètre :** `lib/modules/auth/` (providers, services, screens, widgets), `lib/routes/app_router.dart` (redirection auth-aware), `public.profiles`/`public.pharmacies` (schéma Supabase).
**Consigne du porteur du projet pour ce module :** « privilégier le mode hors-ligne tant que cela est possible » — traité en §4 comme axe de lecture transversal de tout le module, pas comme un point isolé.

---

## 1. Inspection & rapport de situation

Le module est structurellement complet (5 écrans, 1 provider, 2 services, 2 widgets/modèles) et couvre les quatre canaux prévus par le cahier (SMS, WhatsApp, email code, email magic link) via Supabase Auth. L'inspection ligne à ligne fait cependant apparaître que deux des quatre écrans du parcours — `license_verification_screen.dart` et `two_factor_screen.dart` — étaient entièrement simulés (`Future.delayed` puis succès automatique, aucun appel réseau, aucune écriture en base), et qu'un bug du redirect global (`app_router.dart`) les rendait de toute façon inatteignables pour un utilisateur déjà authentifié — c'est-à-dire pour quiconque venait de réussir son OTP.

**Bug de redirection (`app_router.dart`).** La logique de redirection traitait `/2fa` et `/license-verification` comme des écrans « pré-connexion », au même titre que `/login`/`/register`/`/otp` : `if (isAuth && isGoingToAuth) return '/dashboard';`. Or ces deux écrans sont des étapes **post**-authentification (Supabase valide l'OTP avant que `AuthProvider.verifyPhoneOtp`/`verifyEmailOtp` ne les invoque) — `isAuth` est donc déjà vrai à ce moment précis. Conséquence concrète : toute tentative de naviguer vers `/2fa` ou `/license-verification` renvoyait immédiatement vers `/dashboard`, quel que soit le rôle du compte. Corrigé : seuls `/login`, `/register`, `/otp` restent des écrans pré-connexion pour cette règle.

**RG-AUT-01 non implémentée — et sa cause racine.** `license_verification_screen.dart` ne persistait rien nulle part : un `Future.delayed(2s)` suivi d'un message de succès et d'une navigation inconditionnelle vers `/dashboard`. En remontant à la source du schéma (`20260827002000_staff_write_policies.sql`), le code lui-même documente déjà ce trou : *« pharmacy_id est volontairement rempli après vérification de licence (RG-AUT-01), jamais à l'auto-inscription : aucune UI ne l'écrit aujourd'hui (chantier séparé, non couvert ici) »*. La table `public.pharmacies` (`20260827000400_pharmacies.sql`) porte déjà tout le vocabulaire nécessaire (`status`, `license_number`, `license_verified_at`, `manager_id`) et documente elle-même RG-AUT-01 dans son en-tête — mais n'avait qu'une policy `SELECT` : aucune écriture n'était possible, ni pour un pharmacien soumettant sa candidature, ni pour le back-office l'approuvant.

**Conséquence en cascade sur Module 0.** `profiles.pharmacy_id` n'était donc renseigné par *aucun* chemin de code réel. Or l'intégralité de la chaîne d'autorisation `is_pharmacy_staff()` — construite par `staff_write_policies.sql` puis étendue à 8 tables supplémentaires par les correctifs du Module 0 (29/08) — dépend de cette colonne. Sans le correctif de ce module, **aucun pharmacien réel n'aurait jamais pu satisfaire une seule policy d'écriture staff-officine**, quelle que soit la qualité des correctifs RLS déjà livrés. Module 0 avait corrigé *quelle* fonction les policies appellent ; Module 1 corrige le fait que cette fonction n'avait aucune donnée à lire.

**2FA — sécurité décorative.** `two_factor_screen.dart` acceptait n'importe quelle saisie de 6 chiffres comme « vérifiée » après un délai simulé, sans jamais envoyer ni vérifier de code réel (`_send2FACode()` était un corps de fonction vide, commenté « simuler l'envoi »). Le cahier exige pourtant explicitement le 2FA pour les comptes pharmacie, grossiste et administrateur. Combiné au bug de redirection ci-dessus, cet écran était en réalité doublement non fonctionnel : inatteignable *et*, s'il avait été atteint, un simple théâtre de sécurité qui aurait laissé passer n'importe qui.

## 2. Analyse comparative avec le cahier et le Kernel

| Règle | Statut avant ce module | Statut après |
|---|---|---|
| RG-AUT-01 (licence vérifiée avant activation) | Écran simulé, inatteignable, `pharmacy_id` jamais assignable | Soumission réelle (`PharmacyService` → `public.pharmacies`, statut `pending`) ; activation (`pharmacy_id`) réservée au back-office via `is_gsg_admin()` et un trigger dédié |
| RG-AUT-02 (un numéro ↔ un seul compte patient actif) | Garanti par construction pour le canal téléphone (Supabase Auth identifie un compte par numéro) ; non vérifié pour un scénario mixte email+téléphone déclaratif | Inchangé — hors périmètre des corrections de ce module, à surveiller si un mécanisme de fusion de comptes apparaît un jour |
| RG-AUT-03 (traçabilité par identifiant du membre d'officine) | Dépendait d'un `pharmacy_id` qui n'était jamais renseigné (donc vide en pratique) | Devient effectif dès qu'une candidature est approuvée — l'identifiant tracé (`auth.uid()`) était déjà correct dans les tables métier, seul le rattachement manquait |
| RG-AUT-04 (compte suspendu retiré de la recherche patient) | Le champ `pharmacies.status` porte déjà `'suspended'` | Hors périmètre AUT — à vérifier lors de l'audit du module REC (filtrage des résultats de recherche par statut officine) |
| KER-ID-06/07 (E.164, OTP via Supabase Auth, jamais par GSG ID lui-même) | Conforme — `Validators.normalizeE164`, `signInWithOtp`/`verifyOTP` | Inchangé, toujours conforme |
| KER-ARC-03 (indisponibilité du noyau ne bloque jamais le produit) | Conforme — `GsgKernelAuthBridge` : timeout 5s, échec silencieux | Inchangé, toujours conforme |

Aucune nouvelle règle de gestion n'a été inventée : le correctif RG-AUT-01 utilise exclusivement le vocabulaire (`status`, `manager_id`, `license_verified_at`) que la table `pharmacies` portait déjà et documentait elle-même comme l'implémentation prévue de cette règle.

## 3. Sécurité & résilience

| Constat | Risque avant correction | Correction appliquée |
|---|---|---|
| Redirection auth-aware traite les étapes post-connexion comme des écrans pré-connexion | `/2fa` et `/license-verification` inatteignables pour tout utilisateur authentifié | Distinction explicite écrans pré-connexion (`/login`, `/register`, `/otp`) vs post-connexion (`app_router.dart`) |
| `public.pharmacies` sans policy d'écriture | RG-AUT-01 impossible à satisfaire par construction, quel que soit le code client | `pharmacies_insert_own_pending` (pharmacien, sur sa propre candidature, forcée à `status='pending'`) + `pharmacies_update_admin` (`is_gsg_admin()` uniquement) |
| `profiles.pharmacy_id` sans mécanisme d'écriture | Toute la chaîne `is_pharmacy_staff()` (Module 0) inerte pour de vrais utilisateurs | Trigger `link_pharmacy_manager_on_verification()` (SECURITY DEFINER) : rattache automatiquement le manager dès passage à `verified`/`active` — seul point d'écriture de cette colonne, conformément à ce que le code documentait déjà |
| 2FA acceptant n'importe quelle saisie comme valide | Fausse assurance de sécurité sur des comptes classés à risque (pharmacie/grossiste/admin) | Le bouton affiche désormais un état bloqué honnête (« temporairement indisponible ») au lieu de valider n'importe quel code — en attente d'un fournisseur SMS/email pour un second facteur réellement indépendant (blocage déjà documenté pour l'OTP principal, Étape 1 §1.3 point 4) |
| `AuthProvider` ne relisait `role`/`pharmacy_id` qu'au paramètre passé à l'inscription | Un pharmacien qui se *reconnecte* (sans repasser par `register_screen.dart`) n'aurait jamais déclenché `needsLicenseVerification`, même après correction du reste | `_persistProfile` relit désormais systématiquement `role`/`pharmacy_id` depuis la ligne persistée, à l'inscription comme à la connexion |
| `latitude`/`longitude` `NOT NULL` sur `pharmacies` | Bloquait toute insertion en auto-inscription (un pharmacien ne connaît pas ses coordonnées précises) | Rendues nullables ; à compléter par le back-office lors de la vérification (géocodage manuel ou automatique, hors périmètre) |

Aucune régression introduite sur les correctifs du Module 0 : `is_pharmacy_staff()` et `is_gsg_admin()` ne sont pas modifiées, seulement enfin alimentées en données réelles.

## 4. Optimisation & améliorations — lecture « mode hors-ligne »

Conformément à la consigne du porteur du projet, chaque composant du module a été relu sous cet angle spécifique.

**Ce qui est déjà robuste hors-ligne, vérifié dans le code.** La garde de redirection (`SupabaseService().isAuthenticated`, c'est-à-dire `auth.currentUser != null`) est purement locale et synchrone — elle ne fait aucun appel réseau. `supabase_flutter` persiste la session localement par défaut (comportement du SDK, pas une configuration ajoutée par ce projet) : un utilisateur déjà connecté qui rouvre l'application hors connexion reste donc authentifié et accède à l'app, sans être bloqué par ce module. Le pont Kernel (`GsgKernelAuthBridge`) échoue déjà silencieusement en 5s sans jamais bloquer le flux de connexion (KER-ARC-03) — le seul appel réseau non essentiel du module dégrade correctement.

**Ce qui reste non vérifié et devrait faire l'objet d'un test dédié avant d'affirmer une conformité totale.** Le comportement du SDK Supabase quand le rafraîchissement automatique du token échoue faute de réseau (session existante mais expirée pendant une coupure prolongée) n'a pas été testé dans ce projet — la littérature du SDK indique qu'il conserve en général la session existante plutôt que de déconnecter l'utilisateur sur un simple échec réseau, mais ce projet ne le vérifie nulle part explicitement. C'est le premier scénario de test recommandé en §6.

**Ce que ce module ne peut structurellement pas rendre hors-ligne, et pourquoi ce n'est pas un défaut à corriger ici.** L'inscription et la connexion *initiales* reposent sur un aller-retour OTP (SMS/WhatsApp/email) : par construction, la toute première authentification d'un appareil exige un réseau, quel que soit l'effort d'ingénierie — aucune architecture ne peut prouver une identité neuve sans un canal de vérification externe. Prioriser le hors-ligne pour AUT signifie donc concrètement : ne jamais reperdre une session déjà valide, ce qui est déjà le cas aujourd'hui (paragraphe précédent), et ne jamais faire dépendre l'usage du produit d'un appel réseau *après* la connexion initiale — également déjà le cas ici (aucun autre appel réseau obligatoire dans ce module après le login).

**Recommandation concrète pour la suite, hors périmètre strict d'AUT.** La consigne « privilégier le hors-ligne » aura beaucoup plus d'impact sur les modules à venir que sur AUT lui-même. Un point mérite d'être signalé dès maintenant car il concerne indirectement ce module : le développement concurrent du cluster `pos`/`cash`/`sales`/`returns` a fait apparaître un nouveau service `lib/core/services/offline_sales_service.dart` (file d'attente locale sqflite pour les ventes hors-ligne), **distinct et non coordonné** avec le service CARE existant (`offline_sync_service.dart`, sqflite également) et avec les tables serveur `offline_sales_queue`/`offline_product_cache`/`offline_transactions` corrigées au Module 0 — que `offline_sales_service.dart` n'utilise d'ailleurs pas du tout (il écrit directement dans `pos_sales`/`pos_sale_items` à la synchronisation, en contournant les tables de file d'attente serveur prévues à cet effet). Ce service contient par ailleurs un bug probable : `'stock': sqlExpr('stock - $quantity')` — `sqlExpr` n'est pas une fonction du package `sqflite` ; une décrémentation en place nécessite `rawUpdate` avec un `UPDATE ... SET stock = stock - ?`, le `Map` que `db.update()` accepte ne supportant que des valeurs littérales, pas des expressions SQL. Ces deux points (fragmentation des mécanismes hors-ligne, bug de décrémentation) relèvent du module hors-cahier `pos`/`sales` (rang 35 du plan modulaire), pas d'AUT — je les signale ici pour qu'ils soient traités en priorité renforcée quand ce module viendra, conformément à la consigne du jour, plutôt que de les corriger maintenant en marge du module en cours et de rompre la règle du un-module-à-la-fois.

## 5. Documentation API / conformité aux règles métier

**`PharmacyService.submitLicenseVerification(...)`** — insère une ligne `public.pharmacies` avec `manager_id = auth.uid()` et `status = 'pending'` (toute autre valeur de statut est de toute façon rejetée côté serveur par la policy `pharmacies_insert_own_pending`, ce service se contente de refléter honnêtement cette contrainte). Champs requis : `pharmacyName`, `managerName`, `phone` (E.164, via `PhoneInputField`/`Validators.normalizeE164`), `address` ; `licenseNumber` optionnel côté schéma mais demandé par l'écran pour rester fidèle à l'intention de RG-AUT-01.

**`public.pharmacies_insert_own_pending`** *(RLS)* — un utilisateur authentifié peut insérer une ligne dont il est `manager_id`, uniquement à l'état `pending`.

**`public.pharmacies_update_admin`** *(RLS)* — seul `is_gsg_admin()` peut faire progresser une candidature (`pending → verified/active/rejected/underReview`) ou corriger une fiche.

**`public.link_pharmacy_manager_on_verification()`** *(trigger, SECURITY DEFINER)* — dès qu'une officine passe à `verified` ou `active`, rattache automatiquement `profiles.pharmacy_id` de son manager et horodate `license_verified_at` si absent. Implémente littéralement RG-AUT-01 ; seul point d'écriture de `profiles.pharmacy_id` dans tout le projet.

**`AuthProvider.needsLicenseVerification`** — vrai si `role == pharmacien` et `pharmacyId == null`. Calculé après relecture de `public.profiles` (`_persistProfile`), donc valable aussi bien à l'inscription qu'à une reconnexion ultérieure.

## 6. Scénarios de test (unitaires / intégration)

1. **Parcours pharmacien complet.** Inscription (rôle pharmacien) → OTP validé → redirection vers `/license-verification` (pas `/dashboard`) → soumission → redirection vers `/dashboard` avec message "en attente" → tentative d'écriture sur `stock_items` refusée par RLS (`is_pharmacy_staff` renvoie faux, `pharmacy_id` encore nul) → un compte `admin_users` actif passe la pharmacie à `active` → nouvelle connexion du pharmacien → `pharmacy_id` renseigné → écriture sur `stock_items` de son officine acceptée.
2. **Non-régression du redirect.** Un utilisateur non authentifié tentant `/license-verification` ou `/2fa` directement est bien renvoyé vers `/login` (vérifie que la correction n'a pas ouvert ces routes à des utilisateurs non connectés).
3. **Reconnexion sans paramètre role.** Un pharmacien déjà inscrit se reconnecte via `login_screen.dart` (qui ne transmet pas de `role`) : `needsLicenseVerification` doit rester correct (vrai ou faux selon `pharmacy_id`), preuve que la relecture de `_persistProfile` fonctionne indépendamment du paramètre.
4. **Policy `pharmacies_insert_own_pending`.** Une tentative d'insertion avec `status = 'active'` ou `manager_id` différent de `auth.uid()` doit être rejetée par PostgREST (403).
5. **Trigger de rattachement.** Passage manuel (`is_gsg_admin()`) de `status` à `verified` déclenche bien la mise à jour de `profiles.pharmacy_id` du bon utilisateur, et seulement de celui-là (pas d'effet de bord sur d'autres profils).
6. **2FA honnête.** Saisir un code à 6 chiffres sur `/2fa` (accessible directement, hors flux normal) affiche le message de blocage et ne navigue plus vers `/dashboard`.
7. **Persistance de session hors-ligne** *(nouveau, lié à la consigne du jour)* : couper le réseau après une connexion réussie, redémarrer l'application — l'utilisateur doit rester authentifié (session locale persistée) sans être renvoyé vers `/login`. *(Non exécuté dans cette session — nécessite un appareil ou un émulateur, indisponible depuis le pont machine actuel ; à exécuter côté porteur du projet ou lors d'une prochaine session outillée pour les tests d'intégration.)*

## 7. Livrables de ce module

Nouveau : `supabase/migrations/20260829013000_pharmacy_registration.sql`, `lib/modules/auth/services/pharmacy_service.dart`.
Modifiés : `lib/modules/auth/services/profile_service.dart`, `lib/modules/auth/providers/auth_provider.dart`, `lib/modules/auth/screens/otp_verification_screen.dart`, `lib/modules/auth/screens/two_factor_screen.dart`, `lib/modules/auth/screens/license_verification_screen.dart`, `lib/routes/app_router.dart`.
Tous déjà commités dans `PlatformGSG\pharma_connect`.

Signalé pour traitement au tour du module hors-cahier `pos`/`sales` (rang 35) : fragmentation des mécanismes offline (`offline_sales_service.dart` vs `offline_sync_service.dart` vs tables serveur `offline_sales_queue`) et bug probable `sqlExpr(...)` dans `offline_sales_service.dart`.

Signalé pour le module REC (Recherche) : vérifier que RG-AUT-04 (retrait immédiat des résultats de recherche pour une officine suspendue) est bien implémenté côté filtrage de recherche.

Signalé pour le module ADM (Administration) : ce module livre la mécanique serveur de revue des candidatures (`is_gsg_admin()` + policies), mais aucun écran back-office ne permet encore de lister/approuver visuellement les candidatures `pending` — à couvrir lors de l'audit du module ADM (rang 15 du plan).

---

**Le module Authentification & Comptes multi-profils (Module 1 — AUT) est-il totalement clos et validé pour passer au suivant (Module 2 — REC, Recherche & Disponibilité en temps réel) ?**

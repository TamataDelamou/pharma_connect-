# PharmaConnect — Audit Module 25 (PRE — Réseau de prescripteurs & e-prescription)

**Étape 1 — Inspection & rapport de situation**
**Date : 30/08/2026**

---

## 1. Périmètre couvert (rappel cahier)

**Module 25 — PRE — Réseau de prescripteurs & e-prescription.** Différenciant. Axe 5 — Écosystème santé élargi (avec CSR, RCL, CLD).

**Objectif (cahier) :** connecter progressivement les médecins et structures de santé à PharmaConnect afin de fiabiliser l'ordonnance dès son émission et de fermer la boucle entre prescription et dispensation.

**Fonctionnalités clés (cahier) :**
- Espace prescripteur (émission d'ordonnance électronique transmise au patient).
- Vérification automatique des interactions/contre-indications.
- Suivi d'observance par le prescripteur, avec consentement patient.
- Interopérabilité prévue avec les dossiers patients des établissements partenaires.

**Écrans principaux (cahier) :** Espace prescripteur, Émission d'ordonnance électronique, Suivi d'observance (vue prescripteur).

**Règle de gestion — RG-PRE-01 (Critique, seule règle du module) :**
> « Seul un professionnel de santé inscrit à son ordre et vérifié peut émettre une ordonnance électronique opposable sur la plateforme. »

---

## 2. Constat général

Le module `eprescription` est fonctionnellement riche et bien plus avancé qu'un simple CRUD : cycle de statut complet (`draft → sent → received → validated → dispensed / expired / cancelled`), historique de statut auto-journalisé par trigger SQL, génération automatique de numéro de prescription (`RX000001`...), workflow de renouvellement (`isRenewable`/`renewableCount`/`renewableUsed`), et une fonctionnalité de scan OCR d'ordonnance papier (`ScannerService`) absente du cahier mais cohérente avec son esprit (fiabiliser la boucle prescription → dispensation).

Cependant, l'inspection fait apparaître un profil de risque plus sévère que pour la majorité des modules précédents : **RG-PRE-01, seule règle de gestion du module et sa raison d'être opposable, n'est pas appliquée par la RLS** (voir PRE-2 ci-dessous) — un écart directement comparable en gravité à ce qui avait motivé la vigilance particulière portée au Module 24 (ASR), mais ici sur la valeur juridique de l'ordonnance elle-même plutôt que sur un remboursement. Par ailleurs, **trois défauts distincts de nature à bloquer la compilation** ont été repérés par relecture intégrale (PRE-1, PRE-3, PRE-4) — un nombre inédit pour un seul module dans cet audit (le Module 24/ASR n'en avait révélé qu'un, ASR-8, découvert en cours de correctif).

---

## 3. Inventaire du code trouvé

**Dossier `lib/modules/eprescription/`** — 10 fichiers : 3 modèles (`eprescription.dart`, `eprescription_item.dart`, `eprescription_history.dart`), 1 provider (`eprescription_provider.dart`), 2 services (`eprescription_service.dart`, `scanner_service.dart`), 3 écrans (`eprescription_list_screen.dart`, `eprescription_detail_screen.dart`, `scanner_screen.dart`), 1 widget (`eprescription_card.dart`).

**Migrations Supabase concernées :** `20260827009500_eprescription.sql` (`eprescriptions`, `eprescription_items`, `eprescription_history`), `20260828019000_scanned_prescriptions.sql` (`scanned_prescriptions`) — 2 migrations, 4 tables au total.

**Routage (`app_router.dart`, vérifié par lecture directe, pas de mémoire) :** `/eprescription` (liste patient), `/eprescription/doctor` (liste médecin), `/eprescription/pharmacy` (liste pharmacie), `/eprescription/scan` (scanner OCR), `/eprescription/:id` (détail — correctement replacée après ses sœurs statiques depuis le balayage C69 du Module 18). **Aucune route `/eprescription/new` n'existe** — voir PRE-5.

**Menu de navigation.** Confirmé absent de `dashboard_screen.dart` (grep ciblé : la seule entrée « Ordonnances » présente route vers `/prescriptions`, c'est-à-dire le Module 5/ORD — Ordonnances numériques & Lecture assistée — pas ce module) — motif D6, **23ème occurrence** (la 22ème ayant été, après correction de l'erreur de comptage initiale, celle du Module 24/ASR — ce compte sera reconfirmé à la clôture, par prudence après le précédent décalage).

---

## 4. Défauts trouvés à l'ouverture (Étape 1)

### PRE-1 — Défaut de compilation : `.in()` est un mot-clé réservé Dart

`eprescription_service.dart`, ligne 39 :
```dart
if (isActive != null && isActive) {
  query = query.in('status', ['sent', 'received', 'validated']);
}
```
`in` est un mot-clé réservé du langage Dart et ne peut pas être utilisé comme nom de méthode — ceci est une **erreur de syntaxe**, plus grave qu'une simple méthode inexistante (défaut de compilation certain, pas seulement probable). La méthode correcte du client Supabase-Dart, déjà utilisée ailleurs dans ce même projet (`calculateCoverage()` du module ASR), est `.inFilter('colonne', [...])`. Ce défaut bloque la compilation de tout fichier importateur, donc potentiellement de l'application entière — même famille de gravité que ASR-8 (Module 24), mais ici présent dès l'ouverture plutôt que découvert en cours de correctif.

### PRE-2 — RG-PRE-01 non appliquée : aucune vérification de rôle ni de statut de vérification professionnelle (Critique)

Les policies RLS suivantes (`20260827009500_eprescription.sql`) gardent l'émission et la gestion d'une ordonnance électronique **uniquement** par comparaison d'identité, sans aucune autre condition :
```sql
create policy "Doctors manage own prescriptions" on public.eprescriptions
  for all using (auth.uid() = doctor_id);
...
create policy "Items managed with parent" on public.eprescription_items
  for all using (
    exists (select 1 from public.eprescriptions where id = eprescription_id and doctor_id = auth.uid())
  );
```
Aucune de ces deux policies ne vérifie que le compte authentifié possède `profiles.role = 'professionnel'`, ni que `professional_profiles.is_verified = true` (ou `verification_status = 'verified'`) — champs pourtant explicitement prévus à cet effet par le module Professionnels (Module 19/INF, `20260827005500_professionals.sql`, table `professional_profiles` : colonnes `is_verified boolean`, `verification_status text check (... in ('pending','verified','rejected'))`, `license_number`, `license_issuing_body`, `license_expiry_date`).

**Conséquence concrète :** n'importe quel utilisateur authentifié de la plateforme — patient, livreur, grossiste, etc. — peut s'auto-émettre une ordonnance électronique opposable pour n'importe quel patient, en se contentant de renseigner son propre `auth.uid()` comme `doctor_id` à la création. Ceci est une violation directe et sévère de RG-PRE-01, qui est *la seule règle de gestion du module et sa justification métier* (« Seul un professionnel de santé inscrit à son ordre et vérifié peut émettre une ordonnance électronique opposable »). Il s'agit du constat le plus grave de ce rapport d'ouverture.

*Précision de portée* : `professional_profiles` appartient au Module 19 (déjà audité et clos) — cette Étape 1 ne rouvre pas ce module, mais utilise son schéma, déjà en place, comme référence pour caractériser précisément ce que devrait vérifier le correctif RLS de PRE-2 (à traiter à l'Étape 3 de **ce** module, puisque c'est ici que la règle RG-PRE-01 doit être appliquée).

### PRE-3 — Défaut de compilation : accès à un champ privé inter-fichier

`scanner_screen.dart`, ligne 256 :
```dart
final image = await _scannerService._imagePicker.pickImage(source: source);
```
`_imagePicker` est un champ privé (préfixe `_`) déclaré dans `scanner_service.dart` — un fichier **différent**. En Dart, la visibilité privée (`_`) est portée par la *bibliothèque* (le fichier), pas par la classe : un champ privé n'est visible que dans le fichier où il est déclaré. Cet accès `_scannerService._imagePicker` depuis `scanner_screen.dart` ne devrait donc pas compiler — même famille d'erreur que PRE-1 (défaut détectable seulement par relecture, invisible à toute méthodologie de test RLS).

### PRE-4 — Défaut de compilation probable : classe `GoogleMlKit` non résolue par le paquet déclaré

`scanner_service.dart` importe `package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart` et appelle `GoogleMlKit.vision.textRecognizer()`. Vérification faite sur `pubspec.yaml` : seule la dépendance `google_mlkit_text_recognition: ^0.17.1` est déclarée — **pas** `google_ml_kit` (le paquet agrégateur qui expose réellement la classe faîtière `GoogleMlKit`). Le paquet scopé réellement importé expose directement la classe `TextRecognizer` (constructeur direct, ex. `TextRecognizer(script: TextRecognitionScript.latin)`), pas de point d'entrée `GoogleMlKit.vision`. Avec la seule dépendance déclarée dans ce projet, l'identifiant `GoogleMlKit` ne devrait pas se résoudre — un troisième défaut de compilation distinct pour ce seul module.

### PRE-5 — Route « Nouvelle prescription » non déclarée (même classe que ASR-3)

`eprescription_list_screen.dart`, ligne 110 : le bouton « Nouvelle prescription » (visible pour `isDoctor`) appelle `context.push('/eprescription/new')`. Confirmé par lecture directe de `app_router.dart` (pas de mémoire) : aucune route `/eprescription/new` n'est déclarée — la requête serait interceptée par la route dynamique `/eprescription/:id` (`id = 'new'`), qui tente de charger et d'afficher le détail d'une prescription d'identifiant littéral `"new"`, inexistante. Même défaut de shadowing/route manquante que ASR-3 (Module 24). **`eprescription_detail_screen.dart` ne propose aucun mode de création** (écran de consultation/transition de statut uniquement) — comme pour `EnrollmentDetailScreen` avant résolution d'ASR-3, un écran de création dédié serait nécessaire si ce bouton doit fonctionner tel quel ; alternativement, le flux `ScannerService.createFromScan()` (via `/eprescription/scan`) pourrait être la seule voie de création réellement opérationnelle aujourd'hui — à trancher.

### PRE-6 — `isPharmacy` figé à `false` : actions pharmacie inatteignables dans `eprescription_detail_screen.dart`

Ligne 59 : `final isPharmacy = false; // Would check pharmacy staff` — valeur de substitution codée en dur, jamais alimentée par une vérification réelle (`is_pharmacy_staff()`, déjà utilisé côté SQL de ce même module). Conséquence : les actions réservées à la pharmacie sur cet écran (Valider/Refuser une prescription envoyée, Dispenser une prescription validée) sont **définitivement inatteignables dans l'état actuel du code client**, quel que soit le compte connecté — un pharmacien légitime ne peut pas traiter une prescription reçue depuis cet écran.

### PRE-7 — Motif « rôle inatteignable » sur `scanned_prescriptions`

`20260828019000_scanned_prescriptions.sql` :
```sql
create policy "Staff view scanned prescriptions" on public.scanned_prescriptions
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'staff'))
  );
```
Motif déjà rencontré à de nombreuses reprises dans cet audit (C49/C54/.../C94/HOP-1, etc.) : `profiles.role` n'admet jamais `'admin'` ni `'staff'` par contrainte CHECK — cette policy est structurellement inatteignable. Correctif mécanique connu (`public.is_gsg_admin()`), migration datée du 28/08 donc antérieure à `admin_helpers.sql` (29/08) — nécessitera, comme pour les occurrences précédentes, une nouvelle migration corrective plutôt qu'une édition directe du fichier existant.

---

## 5. Observations de périmètre (non-défauts)

- **Frontière de module ambiguë : `scanned_prescriptions`/`ScannerService`.** Cette fonctionnalité (photographier une ordonnance papier, OCR, extraction de médicaments) est physiquement rattachée au dossier Dart `eprescription` et à une migration datée dans le même cluster que ce module — traitée ici à ce titre. Elle pourrait cependant, par nature, relever tout autant du Module 5 (ORD — Ordonnances numériques & Lecture assistée, qui possède son propre dossier `lib/modules/prescriptions/` avec `prescription_upload_screen.dart`). Signalé pour mémoire, sans action à ce stade — aucune duplication ni conflit direct constaté entre les deux dossiers.
- Le module ne comporte, à ce stade de lecture, aucune fonctionnalité de vérification automatique des interactions/contre-indications médicamenteuses ni de suivi d'observance côté prescripteur — deux des quatre fonctionnalités clés du cahier pour ce module. À confirmer en Étape 2 (peut-être portées par un autre module, ex. Module 20/DSN pour le suivi, ou simplement non construites) avant de les qualifier d'écart.
- Interopérabilité avec les dossiers patients des établissements partenaires (cahier) : aucune trace de code trouvée — probablement hors périmètre de correctif, chantier de conception neuve comme pour les écarts différés des modules précédents.

---

## 6. Étape 2 — Analyse comparative au cahier

**RG-PRE-01 (Critique).** Confirmé au sens strict à l'Étape 1 (PRE-2) : la règle n'était appliquée ni au niveau rôle (`profiles.role = 'professionnel'`) ni au niveau vérification (`professional_profiles.is_verified`). Corrigée à l'Étape 3 ci-dessous.

**Fonctionnalités clés du cahier — statut confirmé par relecture complémentaire :**
- Espace prescripteur / émission d'ordonnance électronique transmise au patient : **construit**, cycle de statut complet et réel.
- Vérification automatique des interactions/contre-indications : **absente**, aucune trace de code (recherche par mots-clés `interaction`/`contre-indication`/`contraindication` dans tout `lib/modules`, zéro résultat en dehors de commentaires). Écart de périmètre confirmé, pas une fonctionnalité déportée vers un autre module déjà audité (DSN/Module 20 ne couvre que le dossier de santé consultable, aucun moteur de vérification pharmacologique).
- Suivi d'observance par le prescripteur, avec consentement patient : **absent**, même constat.
- Interopérabilité avec les dossiers patients des établissements partenaires : **absente**, chantier de conception neuve (dépend potentiellement du Kernel/Org Registry, D2, comme d'autres écarts d'interopérabilité déjà rencontrés dans cet audit).

Ces trois écarts correspondent à des chantiers de conception à part entière (moteur de règles pharmacologiques, modélisation du consentement patient pour le partage d'observance, protocole d'interopérabilité inter-établissements) — même famille que les écarts déjà différés aux Modules 16 à 24 (D28/D29/D31/D32/D34/D36/D37/D39/D41). Traités à la clôture ci-dessous (**D43**).

**Frontière `scanned_prescriptions`/`ScannerService` (Module 5/ORD vs Module 25/PRE, signalée à l'Étape 1) :** confirmée sans conflit ni duplication de code après vérification — `lib/modules/prescriptions/` (Module 5) et `lib/modules/eprescription/` (Module 25) ne partagent aucune table ni aucun import croisé. Conservée sous PRE par rattachement physique (dossier + cluster de migration), sans action corrective requise.

---

## 7. Étape 3 — Sécurité & Résilience, corrections vérifiées par exécution réelle

### PRE-1 — corrigé : `.in()` → `.inFilter()`

`eprescription_service.dart`, ligne 39 : remplacé par la méthode réelle du client Supabase-Dart, déjà utilisée correctement ailleurs dans ce projet. Correction syntaxique directe, ne nécessite pas de vérification par exécution Postgres (défaut purement côté client).

### PRE-2 — corrigé et validé par exécution réelle sur Postgres 16 (Critique, RG-PRE-01)

Nouvelle fonction `public.is_verified_professional_account(p_id uuid)` (SECURITY DEFINER, `search_path` verrouillé, même patron que `is_pharmacy_staff()`), vérifiant à la fois `profiles.role = 'professionnel'` **et** `professional_profiles.is_verified = true`. Appliquée aux policies `"Doctors manage own prescriptions"` (`eprescriptions`) et `"Items managed with parent"` (`eprescription_items`), en `USING` et `WITH CHECK`.

**Découverte de coordination inter-modules en cours de correction** : une fonction `public.is_verified_professional(prof_id uuid)` existe déjà (Module 19/INF, correctif RG-INF-01, `20260830046000_professionals_module_fixes.sql`, module déjà clos) — mais elle ne vérifie que `professional_profiles.is_verified`, jamais `profiles.role`, ce qui suffisait dans son contexte d'origine (`homecare_interventions.professional_id`/`consultations.professional_id` référencent déjà structurellement un compte professionnel dans ce module). Ici, `eprescriptions.doctor_id` référence `profiles(id)` sans aucune restriction de rôle — un compte de n'importe quel rôle pourrait en théorie porter une ligne `professional_profiles` orpheline, donc les deux vérifications sont nécessaires. Nouvelle fonction à nom distinct (`is_verified_professional_account`) créée plutôt que de modifier la fonction existante, pour ne pas altérer le comportement déjà scellé et validé du Module 19.

Migration corrective `20260830050000_eprescription_module_fixes.sql`, postérieure à `admin_helpers.sql` (29/08) et à `professionals.sql` (27/08, dont elle dépend) — chaîne complète des **89 migrations** toujours applicable (`run_chain.sh`, `ALL MIGRATIONS APPLIED SUCCESSFULLY`).

**Validation par exécution réelle** (harnais dédié `pre_rls_test.sql`, rôle `authenticated` distinct du propriétaire, RLS effectivement active, `GRANT` par défaut Supabase reproduit explicitement) — **10/10 tests conformes** :
1. Patient P (aucune ligne `professional_profiles`) tente de s'auto-émettre une ordonnance → **bloqué** (`insufficient_privilege`).
2. Faux médecin F (`role='professionnel'`, `is_verified=false`) tente d'émettre une ordonnance → **bloqué**.
3. Vrai médecin D (`role='professionnel'`, `is_verified=true`) émet une ordonnance → **réussi** (contrôle positif — la correction ne bloque pas les médecins légitimes).
4. Patient Q (isolation) ne voit pas l'ordonnance de P → 0 ligne.
5. Patient P voit sa propre ordonnance → 1 ligne.
6. Faux médecin F tente d'ajouter un item à l'ordonnance de D → **bloqué**.
7. Vrai médecin D ajoute un item à sa propre ordonnance → **réussi**.
8. Pharmacien staff S (`role='pharmacien'`, pas `admin_users`) tente de lire un scan via `"Staff view scanned prescriptions"` → 0 ligne (voir PRE-7 ci-dessous).
9. Admin GSG A (`admin_users.is_active`) lit le même scan → 1 ligne (contrôle positif PRE-7).
10. Patient P lit son propre scan via `"Patients manage own..."` → 1 ligne (sanité, policy non modifiée).

### PRE-3 — corrigé : accès à un champ privé inter-fichier

`ScannerService` expose désormais une méthode publique dédiée `pickImage(ImageSource source)` encapsulant `_imagePicker` (au lieu d'exposer le champ lui-même) ; `scanner_screen.dart` appelle cette méthode plutôt que d'accéder directement au champ privé d'un autre fichier. Correction de visibilité Dart pure, sans impact RLS.

### PRE-4 — corrigé : `TextRecognizer` du paquet réellement déclaré

`GoogleMlKit.vision.textRecognizer()` remplacé par l'appel direct au constructeur `TextRecognizer(script: TextRecognitionScript.latin)`, réellement exposé par `google_mlkit_text_recognition` (le seul paquet ML Kit déclaré dans `pubspec.yaml`). Correction d'API pure, sans impact RLS.

### PRE-5 — corrigé : écran de création + route statique

Nouvel écran `EPrescriptionFormScreen` (patient par identifiant UUID — même limite assumée que ASR-3/D42, aucun sélecteur de patient n'existe dans le codebase ; diagnostic, notes, date de validité, renouvellement, et au moins un médicament avec dosage/fréquence/durée/quantité/instructions/substitution). Route statique `/eprescription/new` ajoutée **avant** `/eprescription/:id` (même shadowing go_router déjà rencontré à de multiples reprises, notamment ASR-3). Aucune policy RLS nouvelle requise : le chemin d'écriture s'appuie sur les policies déjà corrigées par PRE-2 (`doctorId` = compte connecté, vérifié par les 10/10 tests ci-dessus).

### PRE-6 — corrigé : `isPharmacy` réellement calculé

`eprescription_detail_screen.dart` calcule désormais `isPharmacy` à partir de `AuthProvider.userRole`/`AuthProvider.pharmacyId` (déjà exposés côté client depuis l'audit du Module 1/AUT) : `role == UserRole.pharmacien && pharmacyId == prescription.pharmacyId` — même logique que `is_pharmacy_staff()` côté SQL, transposée côté client. Les actions Valider/Refuser/Dispenser sont désormais réellement atteignables par le personnel de la pharmacie destinataire, et seulement par lui.

### PRE-7 — corrigé et validé par exécution réelle (motif « rôle inatteignable »)

`"Staff view scanned prescriptions"` remplacée par `using (public.is_gsg_admin())`, même migration corrective que PRE-2. Validé par les tests 8/9 ci-dessus (0 ligne pour un pharmacien non-admin, 1 ligne pour un compte `admin_users.is_active`).

### Fichiers livrés et déployés sur l'appareil de l'utilisateur

`eprescription_service.dart`, `scanner_service.dart`, `scanner_screen.dart`, `eprescription_detail_screen.dart`, `app_router.dart`, `dashboard_screen.dart`, nouveau `eprescription_form_screen.dart`, nouvelle migration `20260830050000_eprescription_module_fixes.sql` — 8 fichiers.

### Navigation (motif D6, 23ème occurrence) — appliquée immédiatement

Sur instruction explicite du porteur du projet (« confirmez la présence de la navigation au menu »), l'entrée « e-Prescriptions » a été ajoutée à `_effectiveNavItems()` (`dashboard_screen.dart`), exposée à tout rôle authentifié — sans étape d'arbitrage séparée cette fois, la correction de RG-PRE-01 (PRE-2) et des 3 défauts de compilation (PRE-1/PRE-3/PRE-4) rendant le module réellement fonctionnel et sécurisé dès ce tour. **Confirmé : 23ème occurrence, cohérente avec le compte du registre depuis la 22ème (Module 24/ASR).**

---

## 8. Clôture — arbitrage et validation du porteur du projet (30/08/2026)

Le porteur du projet a donné (message du 30/08/2026) un feu vert explicite et complet pour l'exécution des Étapes 2 et 3 et la clôture du Module 25 sur la base du rapport d'ouverture, avec trois instructions précises : corriger en priorité absolue les RLS, appliquer l'ensemble des correctifs Dart/Flutter, mettre à jour la documentation/le registre et confirmer la navigation. Les trois ont été exécutées ci-dessus.

### Écarts de périmètre cahier (vérification automatique des interactions, suivi d'observance, interopérabilité établissements partenaires)

**Traitement appliqué : différer ces trois chantiers à une phase de conception dédiée**, par cohérence avec le traitement unanime de tous les écarts de périmètre cahier rencontrés dans cet audit depuis le Module 16 (D28/D29/D31/D32/D34/D36/D37/D39/D41) — aucun de ces chantiers ne relève d'un correctif de sécurisation ou de compilation, chacun nécessite une conception produit à part entière (moteur de règles pharmacologiques, modèle de consentement patient, protocole d'interopérabilité inter-établissements). **Consigné sous le ticket D43.**

### Résumé des actions de clôture

- **RG-PRE-01 sécurisée et validée par exécution réelle** : PRE-2, fonction `is_verified_professional_account()` + policies `eprescriptions`/`eprescription_items` corrigées, 10/10 tests Postgres 16 conformes (harnais `pre_rls_test.sql`), chaîne complète des 89 migrations toujours applicable.
- **PRE-7 corrigé et validé** dans le même mouvement (`is_gsg_admin()` sur `scanned_prescriptions`).
- **Trois défauts de compilation corrigés** : PRE-1 (`.inFilter()`), PRE-3 (méthode publique dédiée), PRE-4 (API `TextRecognizer` correcte).
- **PRE-5 corrigé** : écran de création `EPrescriptionFormScreen` + route `/eprescription/new`.
- **PRE-6 corrigé** : `isPharmacy` réellement calculé via `AuthProvider`.
- **Navigation** : entrée « e-Prescriptions » exposée immédiatement au menu principal (23ème occurrence de D6, confirmée et corrigée).
- **Écarts de périmètre cahier** (vérification interactions, suivi d'observance, interopérabilité établissements) différés, chantier de conception dédié (**D43**).

**Le Module 25 (PRE — Réseau de prescripteurs & e-prescription) est officiellement clos, scellé et validé.**

**Passation au Module 26.** Numérotation à confirmer contre la table officielle du cahier : 26 = CHN (priorité Standard).

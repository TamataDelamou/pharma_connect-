# PharmaConnect — Audit Module 5 (ORD — Ordonnances numériques & lecture assistée)

Date : 29/08/2026
Méthodologie : cahier de conception v2/v3, RG-ORD-01/02/03, directives standing (offline réel, UX, registre des écarts, fonctionnalités attrayantes).

---

## 1. Inspection & rapport de situation

### Périmètre relu
`lib/modules/prescriptions/` en intégralité (4 modèles, 1 provider, 2 services, 5 écrans, 4 widgets) + 3 migrations (`prescriptions`, `scanned_prescriptions`, `eprescriptions`).

### Ce qui existait avant cet audit
- OCR on-device (ML Kit) avec parsing regex du texte (nom/dosage/fréquence/durée), score de confiance, correction assistée par distance de Levenshtein sur le catalogue.
- Écrans de dépôt, prévisualisation/validation, détail, liste filtrée par statut, historique patient.
- Un cycle de statut correct sur le papier : `draft → pending → validated → dispensed / archived`.
- Un badge de confiance OCR par ligne et global, une suggestion de substitution générique.

### Ce qui ne fonctionnait pas du tout
- **Dépôt d'ordonnance impossible en production** : `prescriptions`/`prescription_items` n'avaient que des policies RLS `SELECT` ; aucune policy `INSERT`. Toute tentative de dépôt patient échouait côté serveur.
- **Validation/dispensation impossibles en production** : aucune policy `UPDATE` sur ces deux tables non plus.
- **Identité patient simulée** : `prescription_upload_screen.dart` envoyait `patientId = 'patient_123'` (pas un uuid — le type de colonne est `uuid`) et `patientName = 'Jean Dupont'` en dur, quel que soit l'utilisateur connecté.
- **Aucune vérification de rôle, nulle part** : n'importe quel utilisateur consultant l'écran de détail — y compris le patient propriétaire — voyait et pouvait actionner "Valider l'ordonnance" et "Dispenser", en violation directe de RG-ORD-01.
- **Disponibilité produit simulée** : `_checkAvailability` tirait un booléen sur l'horloge système (`millisecondsSinceEpoch % 3`), sans consulter le stock réel.
- **`upload_guidance_overlay.dart`** entièrement construit (conseils photo) mais jamais référencé nulle part — écran mort.

---

## 2. Analyse comparative (cahier vs code)

| Exigence cahier (ORD) | État avant | État après |
|---|---|---|
| Dépôt photo/PDF horodaté | Photo OK (image_picker), horodatage OK (`uploaded_at`) | Inchangé |
| Pré-lecture OCR à validation humaine obligatoire | OCR OK, mais **aucune barrière de rôle** avant validation | Barrière RLS + UI (voir §3) |
| Réception d'ordonnances électroniques d'un prescripteur inscrit | Schéma `eprescriptions` complet (RG-PRE-01) **mais zéro code Dart ne l'utilise** — `e_prescription.dart` est un modèle orphelin | Inchangé fonctionnellement (RLS corrigée, voir §3) — écart documenté au registre |
| Détection d'interactions médicamenteuses / doublons | **Absent du code** — aucune trace | Non traité (hors budget de ce module), documenté |
| Archivage réglementaire à durée paramétrable | Statut `archived` existe, aucune purge/rétention paramétrable | Non traité, documenté |

---

## 3. Sécurité & résilience

### 3.1 RG-ORD-01 — violation confirmée et corrigée
« Aucune extraction automatique issue de l'OCR/IA ne peut déclencher une dispensation sans validation explicite d'un pharmacien habilité. »

Avant cet audit, cette règle n'était protégée ni côté serveur ni côté client :
- Côté serveur : `prescriptions`/`prescription_items` n'avaient aucune policy `UPDATE` — en théorie personne ne pouvait valider, y compris un vrai pharmacien.
- Côté client : l'écran affichait les boutons Valider/Dispenser/Archiver sans aucune condition de rôle.

**Corrigé** :
- Migration `20260829016000` : nouvelle fonction `public.is_pharmacist()` (SECURITY DEFINER, même patron que `is_pharmacy_staff`/`is_gsg_admin`), policies `prescriptions_insert_own` / `prescriptions_staff_select` / `prescriptions_staff_update` (+ équivalents `prescription_items`).
- `prescription_detail_screen.dart` : les actions Valider/Dispenser/Archiver ne s'affichent plus qu'à `AuthProvider.userRole == UserRole.pharmacien` ; un patient voit désormais un rappel de statut en lecture seule.

**Décision documentée, non tranchée ici** : `prescriptions` n'a pas de colonne `pharmacy_id` (contrairement au stock) et le cahier ne précise pas quelle officine valide une ordonnance déposée par OCR — la policy staff n'est donc **pas** scopée par officine (tout compte `pharmacien` peut valider n'importe quelle ordonnance de la plateforme). Inventer un rattachement officine ici aurait été spéculatif. Voir registre, item D.

### 3.2 Faille RLS critique trouvée dans `eprescriptions` (non liée à RG-ORD-01, découverte en cours d'audit)
Les policies "Pharmacies view/update prescriptions" comparaient `pharmacy_staff.pharmacy_id = pharmacy_id` — une auto-référence de colonne (toujours vraie) au lieu de `pharmacy_staff.pharmacy_id = eprescriptions.pharmacy_id`. **N'importe quel pharmacien du réseau pouvait lire/valider/dispenser n'importe quelle e-prescription de n'importe quelle officine.** Ce module n'est câblé à aucun écran Dart (voir §2), mais RLS est la seule ligne de défense d'une table Supabase — un appel API direct l'aurait exploitée sans code Flutter. Corrigé en réutilisant `is_pharmacy_staff(pharmacy_id)`, déjà en place ailleurs.

### 3.3 Test de rôle cassé dans `scanned_prescriptions` (même classe de bug déjà identifiée en Module 0, occurrence non corrigée à l'époque)
`role in ('admin', 'staff')` — ces valeurs ne sont pas autorisées par la contrainte CHECK de `profiles.role`. Policy structurellement inatteignable. Corrigée avec `is_pharmacist()`.

### 3.4 Identité patient en dur (même famille de bug que le `'admin'` du Module 4)
`prescription_upload_screen.dart` envoyait un id non-uuid — chaque dépôt échouait en base avec une erreur de cast Postgres. Corrigé : `AuthProvider.userId` (avec garde si non connecté) + nom réel via un nouveau `ProfileService.getFullName()`.

### 3.5 RG-ORD-02 — non implémenté, amorcé
« Une ordonnance pour un produit stupéfiant doit être conservée sous forme d'original vérifiable et honorée uniquement par retrait physique en officine. »
`PrescriptionItem` ne référence aucun `product_id` — impossible de savoir si une ligne concerne un produit `regulatory_class = stupefiant/psychotrope` (Module 3). Amorcé : `_checkAvailability` fait désormais une recherche catalogue par nom et affiche un badge "Stupéfiant — retrait en officine uniquement" quand une correspondance est trouvée. **Non bloquant et non exhaustif** (dépend d'une correspondance de nom, pas d'un lien structurel) — l'application effective (empêcher une livraison à domicile pour cette ligne) dépend du module Livraison, pas encore audité. Documenté au registre.

### 3.6 RG-ORD-03 — conforme
Aucune génération de suggestion de diagnostic/posologie trouvée : l'OCR transcrit le texte de l'ordonnance (regex sur dosage/fréquence déjà écrits par le médecin), il n'invente rien. Le champ `eprescriptions.diagnosis` est renseigné par le prescripteur, jamais par l'app.

### 3.7 Découverte hors RG-ORD : `patient_history_screen.dart` ne filtre pas par patient
L'écran accepte un `patientId` en paramètre de route mais ne l'utilise **jamais** — ni pour charger, ni pour filtrer. Il affiche simplement `provider.prescriptions`, quel que soit son contenu au moment de la navigation. La fonctionnalité "historique d'un patient donné" n'est donc pas réellement implémentée, et RG-SEC-01 (consentement patient pour l'accès tiers à l'historique) ne peut pas s'appliquer à une fonctionnalité qui n'existe pas encore. Non corrigé ici (nécessite une nouvelle méthode `getPrescriptionsForPatient` + une décision produit sur le consentement) — documenté au registre.

### 3.8 Recoupement avec la dette déjà connue
`_service.createPrescription`/`validatePrescription` etc. suivent déjà la bonne discipline (pas de `sqlExpr`, pas de `.maybeSingle()` fragile).

---

## 4. Optimisation & améliorations (directives standing)

### 4.1 Mode hors-ligne — implémenté, pas seulement documenté
- `OfflineSyncService` (v3→v4) : nouvelle table `cache_prescriptions` (patron identique à `cache_stock_items` du Module 4), partitionnée par utilisateur authentifié.
- `loadPrescriptions()` : cache la dernière liste réussie, s'y replie avec un message informatif (jamais un état bloquant) si le réseau échoue — même patron que `SearchProvider`/`StockProvider`.
- `loadPrescription(id)` : repli sur le cache si le réseau échoue en ouvrant le détail d'une ordonnance déjà vue.
- `uploadPrescription()` : l'OCR (on-device, ML Kit) fonctionne déjà hors-ligne ; c'est l'écriture Supabase qui ne l'était pas. Sur coupure réseau (ou échec réseau malgré une connectivité apparente), l'ordonnance et ses lignes sont mises en file d'attente locale (id générés côté client, rejoués tels quels par `syncAll()`), affichées immédiatement au patient avec un badge "hors connexion" non alarmant.
- Bug évité au passage : `Prescription.toJson()` n'inclut jamais `items` (table séparée) — un cache naïf aurait fait revenir des ordonnances sans médicaments après un repli hors-ligne. Corrigé par un encodage dédié qui réinjecte `prescription_items`.
- Bug évité au passage (n°2) : le message informatif "hors connexion" est stocké dans le même champ `error` que les vraies erreurs (patron déjà établi en Module 2/4) — sans garde `&& prescriptions.isEmpty` sur les écrans liste, l'écran plein-erreur aurait masqué la liste mise en cache. Corrigé sur `prescription_list_screen.dart` et `patient_history_screen.dart`.

### 4.2 UX
- `upload_guidance_overlay.dart` (mort) est maintenant affiché une fois par visite de l'écran de dépôt, avant la première prise de photo.
- Bandeau hors-ligne cohérent visuellement avec le Module 4 (`accentAmber`, icône `cloud_off`) sur liste, détail et dépôt.
- Erreur de sélection d'image (permission refusée, etc.) : n'est plus avalée silencieusement, un message s'affiche.
- Rappel de statut clair pour un patient consultant une ordonnance en attente/validée (au lieu de rien, ou pire, de boutons d'action qui n'auraient jamais dû lui être montrés).

### 4.3 Fonctionnalité plus utile (remplace une simulation)
`_checkAvailability` interroge désormais réellement `CatalogService`/`StockService.searchStock` (toutes officines, aucune officine n'étant encore choisie à ce stade) au lieu d'un booléen aléatoire — et amorce RG-ORD-02 au passage (badge stupéfiant).

---

## 5. Documentation API (services)

`PrescriptionService` (inchangé dans sa forme, RLS sous-jacente corrigée) :
- `getPrescriptions({status})`, `getPrescription(id)`, `createPrescription(...)`, `validatePrescription(id, {notes})`, `dispensePrescription(id)`, `archivePrescription(id)`, `searchPrescriptions(query)`.

`ProfileService` (ajout) :
- `Future<String?> getFullName(String userId)` — lecture best-effort de `profiles.full_name`.

`OfflineSyncService` (ajout) :
- `cachePrescriptions(ownerKey, items)`, `getCachedPrescriptions(ownerKey)`, `upsertCachedPrescription(ownerKey, item)`.

RLS (migration `20260829016000`) :
- `public.is_pharmacist()` — vrai si `profiles.role = 'pharmacien'`, sans égard à l'officine.
- `prescriptions_insert_own`, `prescriptions_staff_select`, `prescriptions_staff_update` (+ équivalents `prescription_items`).
- Correctif `eprescriptions`/`eprescription_items`/`eprescription_history` (faille d'auto-référence).
- Correctif `scanned_prescriptions` (rôle inatteignable).

---

## 6. Scénarios de test (à couvrir — aucun test automatisé n'existe dans ce module, comme pour les précédents)

1. Un patient dépose une ordonnance → une ligne apparaît dans `prescriptions` avec `patient_id = auth.uid()` (uuid réel, plus jamais `'patient_123'`).
2. Un patient consulte sa propre ordonnance `pending` → ne voit **aucun** bouton Valider/Dispenser/Archiver, seulement un rappel de statut.
3. Un compte `role = pharmacien` consulte la même ordonnance → voit et peut actionner Valider/Dispenser/Archiver.
4. Un compte `role = patient` tente un `UPDATE` direct sur `prescriptions` (hors UI, ex. via l'API REST) → refusé par RLS.
5. Dépôt d'ordonnance hors connexion → l'ordonnance apparaît immédiatement dans "mes ordonnances" avec un badge "hors connexion" ; au retour du réseau, `syncAll()` l'envoie sans duplication (id générés côté client).
6. Liste d'ordonnances hors connexion avec cache existant → la liste mise en cache s'affiche avec un bandeau ambre, jamais un écran d'erreur plein.
7. Un item d'ordonnance correspondant à un produit `regulatory_class = stupefiant` → badge "Stupéfiant — retrait en officine uniquement" visible à l'écran de validation.
8. Un pharmacien via l'API REST tente de lire une `eprescription` d'une officine à laquelle il n'est pas rattaché → refusé (avant ce correctif : autorisé).
9. `patient_history_screen.dart` avec deux patients différents en base → actuellement affiche la même liste quel que soit le `patientId` passé en route (bug documenté, non corrigé — voir registre).

---

## 7. Livrables de ce module

- 1 migration : `supabase/migrations/20260829016000_prescriptions_module_fixes.sql`.
- 9 fichiers Dart modifiés : `profile_service.dart`, `offline_sync_service.dart`, `prescription_provider.dart`, `prescription_upload_screen.dart`, `prescription_detail_screen.dart`, `prescription_list_screen.dart`, `patient_history_screen.dart`, `prescription_preview_screen.dart`, `prescription_item_tile.dart`.
- Registre des écarts mis à jour (`PharmaConnect_Registre_Ecarts_A_Verifier.md`).

---

**Le module ORD est-il totalement clos et validé pour passer au suivant ?**

# Phase 8 — Consignes pour Claude Code : correction des erreurs de compilation dans `test/`

**Rédigé par :** session d'audit (Cowork), sans `flutter`/`dart` disponible dans son pont machine actuel — n'a donc pas pu ré-exécuter `flutter analyze`/`flutter test` elle-même pour vérifier le chiffre de 97 erreurs annoncé. Ce document démarre volontairement par une ré-inspection factuelle plutôt que de traiter 97 comme acquis, dans la continuité de la discipline déjà en vigueur sur ce dépôt (vérification systématique plutôt qu'affirmation non vérifiée — voir `PharmaConnect_Etape1_Audit_Global.md` §1.1).
**Destinataire :** Claude Code, exécuté localement avec `flutter`/`dart` installés.
**Date :** 20/09/2026
**Contexte :** suite du plan validé par le porteur du projet — Module 9 (BIZ) clos comme non entamé (`PharmaConnect_Module9_Audit_Cloture.md`), cluster hors-cahier `business`/`pos`/`cash`/`sales`/`returns` laissé de côté (voir C148/C149 du registre) en attendant une session de cadrage dédiée de 30 min. Phase 8 = tâche mécanique de fond, sans décision de règle métier — toute décision de ce type rencontrée en cours de route doit être remontée au porteur du projet, pas tranchée par Claude Code.

---

## 0. Périmètre et règle du jeu

- Champ d'application strict : uniquement `test/` (`test/unit/`, `test/widget/`). Ne pas modifier `lib/` ni `supabase/migrations/`.
- Objectif : `flutter analyze test/` et `flutter test` sans erreur de compilation, sans changer ce qu'un test vérifie ni le comportement du code testé.
- **Répartition des rôles** (rappel explicite du porteur du projet) : Claude Code exécute les corrections mécaniques et rédige le rapport ; toute décision touchant une règle métier (RG-*) reste au porteur du projet — ne pas trancher seul, consigner en section 5 ci-dessous et arrêter sur ce point précis plutôt que de deviner.
- Cluster hors-cahier (`business`, `pos`, `cash`, `sales`, `returns`) : ne pas traiter leurs tests en priorité. Exception : si un test cassé dans ce cluster bloque la compilation globale de `test/` (erreur qui empêche `flutter test` de démarrer), correction strictement mécanique autorisée mais signalée à part dans le rapport, sans devenir une revue de fond de ces modules.

## 1. Étape préalable — Inspection & rapport de situation (obligatoire avant toute correction)

1. `flutter pub get`
2. `flutter analyze test/ 2>&1 | tee phase8_analyze.log`
3. `flutter test 2>&1 | tee phase8_test.log`
4. Construire un tableau récapitulatif réel (fichier, ligne, catégorie d'erreur — import cassé, méthode/champ renommé côté `lib/` non répercuté dans `test/`, signature de constructeur désynchronisée, mock obsolète, typage, autre) avant toute correction. Confirmer ou corriger le chiffre de 97 avec le compte réel obtenu.
5. Regrouper par module (même découpage que les commits `fix(test): ...` déjà présents dans l'historique — `git log --oneline` récent en donne le ton).

## 2. Corrections — mécaniques uniquement

**Autorisé sans validation :**
- imports cassés ou obsolètes ;
- appels à des méthodes/champs renommés ou supprimés côté `lib/` depuis l'écriture du test, non répercutés ;
- signatures de constructeur/factory désynchronisées entre le modèle et son test ;
- mocks à régénérer ou à mettre à jour sur un contrat inchangé ;
- erreurs de typage triviales (`int` vs `double`, nullabilité, etc.).

**Interdit sans validation explicite du porteur du projet :**
- supprimer un test qui échoue plutôt que le corriger ;
- changer l'assertion attendue pour qu'elle corresponde au comportement actuel du code — cela masquerait une régression réelle plutôt que de la révéler ;
- modifier du code dans `lib/` pour faire passer un test.

**Cas particulier :** une erreur qui ne se résout pas par une correction mécanique — parce qu'elle révèle un vrai bug dans `lib/`, ou une divergence de règle métier — n'est **pas** corrigée sur place. Elle est consignée comme ticket séparé (nouveau `C15x`, en continuant la numérotation à partir de C149 dans `PharmaConnect_Registre_Ecarts_A_Verifier.md`, section C), et Claude Code passe à l'erreur suivante.

## 3. Vérification et commits

- Après chaque lot logique (par module ou par catégorie d'erreur), relancer `flutter analyze test/` et `flutter test` pour confirmer la progression avant de committer.
- Un commit par lot, message au format déjà en usage sur ce dépôt : `fix(test): <résumé court>` (voir les 15 derniers commits `fix(...)` pour le ton exact).
- Pas de `git add -A` : lister explicitement les fichiers touchés dans chaque commit.
- Ne rien committer qui ne compile pas — chaque commit doit laisser `test/` dans un état au moins aussi propre qu'avant.

## 4. Livrable attendu

- Rapport final, même format que les clôtures de module déjà produites (`PharmaConnect_Module0_Audit_Cloture.md` en référence de style) :
  - nombre d'erreurs réel au départ (issu de l'étape 1, pas supposé) ;
  - nombre corrigées mécaniquement, par catégorie ;
  - liste des tickets `C15x` non résolus consignés au registre, avec leur nature ;
  - sortie finale de `flutter analyze test/` et `flutter test` (0 erreur visé, sinon expliquer pourquoi).
- Mise à jour de `PharmaConnect_Registre_Ecarts_A_Verifier.md` : nouvelle entrée de tête « Phase 8 clôturée » + tickets `C15x` éventuels, même format que l'entrée Module 9 ajoutée le 20/09/2026.

## 5. Décisions de règle métier remontées (à remplir par Claude Code en cours de route)

*(Section à compléter si une erreur de `test/` révèle une divergence de règle métier ou un choix de conception non tranché — ne pas décider ici, décrire le dilemme et attendre l'arbitrage du porteur du projet.)*

---

**Question à trancher par le porteur du projet une fois ce document exécuté :** la Phase 8 est-elle close (0 erreur de compilation dans `test/`, tickets `C15x` actés au registre) pour enchaîner sur le Module 29 (CSR) ?

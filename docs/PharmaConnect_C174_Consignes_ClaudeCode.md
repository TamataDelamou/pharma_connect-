# C174 — Migration de création `solidarity` manquante sur `main`

**Rédigé par :** session d'audit (Cowork), 26/09/2026 — traité séparément de la réconciliation `main`/`consolidation-wip-20260921` (D54), à la demande du porteur du projet.
**Destinataire :** Claude Code, dans le dépôt `pharma_connect`, sur `main`.
**Contexte :** en vérifiant le rapport de réconciliation D54, une 3ᵉ découverte signalée par Claude Code (« non corrigée, hors mandat ») a été confirmée par lecture directe : `supabase/migrations/20260906080000_solidarity_module_fixes.sql` (déjà sur `main` depuis le 22/09) modifie `public.solidarity_beneficiaries`, mais **aucune migration sur `main` ne crée les tables `solidarity_*`** — la migration de création, `supabase/migrations/20260827009000_solidarity.sql`, existe bien sur `consolidation-wip-20260921` mais n'a jamais été portée sur `main` lors de la réconciliation du 22/09. J'ai vérifié en parallèle les 3 autres migrations `*_module_fixes.sql` qui modifient une table (`deliveries`, `homecare_interventions`, `user_dashboards`) : leurs migrations de création sont bien présentes sur `main` — seul `solidarity` a ce trou. J'ai aussi vérifié le contenu de la migration manquante : elle crée `solidarity_programs`, `solidarity_beneficiaries`, `solidarity_distributions`, `solidarity_donations` (+ index + policies), sans collision avec quoi que ce soit de déjà présent sur `main`, et son horodatage (`20260827009000`) la place bien avant `20260906080000_solidarity_module_fixes.sql` qui en dépend — ordre correct une fois restaurée.

## Correctif

```bash
git checkout main
git checkout consolidation-wip-20260921 -- supabase/migrations/20260827009000_solidarity.sql
git add supabase/migrations/20260827009000_solidarity.sql
git commit -m "fix(solidarity): restore missing table-creation migration 20260827009000_solidarity.sql (C174)"
```

## Vérification demandée

1. Confirmer qu'aucun autre fichier de migration sur `main`, daté entre le 27/08 et le 06/09/2026, ne référence une table `solidarity_*` avant cette restauration (sinon signaler lequel).
2. Si un accès Postgres réel est disponible pour ce dépôt (`supabase db push` ou équivalent en local/staging), lancer une validation à blanc de l'ordre des migrations sur ce cluster ; sinon, se limiter à la vérification de cohérence des noms de fichiers/horodatages ci-dessus et le signaler clairement dans le rapport (ne pas prétendre avoir exécuté une validation Postgres qui n'a pas eu lieu).
3. `flutter analyze lib/` — ce correctif ne touche aucun fichier Dart, le total ne doit pas bouger ; le confirmer quand même pour détecter toute régression inattendue.

## Registre

Ajouter au registre (`docs/PharmaConnect_Registre_Ecarts_A_Verifier.md`), à la suite de C173 :

```markdown
**C174 — résolu le 26/09/2026** — `supabase/migrations/20260827009000_solidarity.sql` (création des tables `solidarity_programs`/`solidarity_beneficiaries`/`solidarity_distributions`/`solidarity_donations`) manquait sur `main` alors que `20260906080000_solidarity_module_fixes.sql`, déjà réconciliée le 22/09/2026, altère `solidarity_beneficiaries` — trouvé en vérifiant le rapport de réconciliation D54, traité séparément à la demande du porteur du projet. Restaurée depuis `consolidation-wip-20260921` (où elle existait déjà), aucune collision, ordre chronologique vérifié correct (20260827009000 précède 20260906080000). Les 3 autres migrations `*_module_fixes.sql` altérant une table existante (`deliveries`, `homecare_interventions`, `user_dashboards`) ont été vérifiées saines (migration de création bien présente sur `main`) ; `counterfeit_reports` crée et modifie la table dans le même fichier, pas un cas similaire.
```

## Rapport attendu

Hash du commit, confirmation du contenu restauré (diff ou `git show --stat`), résultat de la vérification d'ordre chronologique, et `flutter analyze lib/` (total inchangé attendu). Je vérifie par lecture directe avant de considérer C174 clos.

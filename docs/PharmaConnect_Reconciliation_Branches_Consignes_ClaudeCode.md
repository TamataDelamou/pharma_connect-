# Réconciliation `main` ↔ `consolidation-wip-20260921` — Consignes Claude Code

**Rédigé par :** session d'audit (Cowork), 26/09/2026, à la suite d'une vérification croisée demandée explicitement par le porteur du projet (« vérifions tous ensemble pour confirmer la fiabilité du code »).
**Destinataire :** Claude Code, exécuté localement avec `git`/`flutter`/`dart` installés, dans le dépôt `pharma_connect`.
**Nature de l'opération :** git (branches, merge, commits), pas de nouvelle logique métier à inventer — restauration mécanique de fichiers déjà écrits et déjà vérifiés sur `consolidation-wip-20260921`, à l'identique du protocole déjà appliqué 27 fois sur `main` le 22/09/2026 (commits `92cee28` → `a8914fb`, préfixe `reconciliation(...)`).

---

## 0. Contexte (à ne pas re-découvrir, juste vérifier que ça correspond)

Le dépôt a deux lignées depuis l'ancêtre commun `c469ce3` (20/09/2026) :

- **`main`** (HEAD `5b6e84e`) : a déjà récupéré, le 22/09/2026, la quasi-totalité de l'audit historique (Modules 1 à 29, AUT/REC/CAT/STK/ORD/RES/LIV/PAY/ALR/TRC/B2B/FIN/CNS/TRI/HOM/INF/DSN/IOT/FAM/HOP/ASR/PRE/CHN/REG/BI/CSR/SAV) **depuis `consolidation-wip-20260921`**, module par module, un commit par module, préfixe `reconciliation(...)`. Module 11 (AI/forecast) est resté volontairement différé (« hors périmètre forecast/IA »), exactement comme notre propre ticket **C165**. Puis, plus tard le même jour (20h10-20h12), une session distincte a poursuivi seule le module `support/` (commits `2bcf275`/`c37e7f2`/`55b0edc`/`5b6e84e`) en réutilisant par erreur, sans visibilité sur notre registre (absent de `main`), les numéros **C158 à C163** — déjà pris de notre côté pour tout autre chose.
- **`consolidation-wip-20260921`** (HEAD `335aa0f`, 1 commit après `pre-consolidation-20260921-safety`) : contient tout notre travail d'audit de cette session et de la précédente, avec le registre complet (`docs/PharmaConnect_Registre_Ecarts_A_Verifier.md`). Ce qui **n'a pas encore été porté sur `main`** se limite à : le cluster hors-cahier `business/`, `pos/`, `sales/`, `cash/`, `returns/` (en cours d'audit ce tour-ci — C150 à C166, D53), le cluster IA/forecast (C165, différé des deux côtés, ne pas toucher), et la documentation (`docs/`, `STRUCTURE_PROJET.md`).

Décisions actées par le porteur du projet (26/09/2026) :
1. Les 6 tickets en collision (**C158-C163**, cluster pos/sales/cash/returns) sont **renumérotés C167-C172** ; les tickets `support/` de `main` gardent leurs numéros actuels.
2. `consolidation-wip-20260921` est **réconcilié dans `main`**, en suivant le même protocole que celui déjà appliqué 27 fois (un commit par module, préfixe `reconciliation(...)`), plutôt qu'un `git merge` global en un seul commit — plus facile à vérifier un module à la fois, et cohérent avec l'historique déjà en place.

Une découverte annexe faite en creusant `lib/app.dart` (à corriger au passage, nouveau ticket **C173**) : sur `consolidation-wip-20260921`, `AuthProvider()`, `DashboardProvider()` et `SearchProvider()` sont chacun déclarés **deux fois** dans le `MultiProvider` (lignes 60-62 puis à nouveau 63-65 de `lib/app.dart`) — doublon inoffensif à l'exécution (Provider retient la première instance) mais à nettoyer.

---

## Phase 0 — Sécurité

```bash
git checkout main
git status   # doit être propre
git branch main-avant-reconciliation-hors-cahier-20260926   # filet de sécurité, ne jamais push ni supprimer sans validation explicite
```

Ne rien faire d'autre tant que cette branche de sécurité n'est pas créée.

---

## Phase 1 — Renumérotation C158-C163 → C167-C172, sur `consolidation-wip-20260921`

```bash
git checkout consolidation-wip-20260921
```

Écrire et exécuter ce script Python (adapter le chemin si besoin), qui renumérote **uniquement** dans le registre, sans toucher aux messages de commit déjà écrits (l'historique git reste tel quel — la correspondance ancien/nouveau numéro est documentée dans le registre lui-même pour la traçabilité) :

```python
import re, pathlib

p = pathlib.Path("docs/PharmaConnect_Registre_Ecarts_A_Verifier.md")
text = p.read_text(encoding="utf-8")

mapping = {
    "C158": "C167",
    "C159": "C168",
    "C160": "C169",
    "C161": "C170",
    "C162": "C171",
    "C163": "C172",
}

counts = {}
for old, new in mapping.items():
    pattern = re.compile(r"\b" + old + r"\b")
    counts[old] = len(pattern.findall(text))
    text = pattern.sub(new, text)

for old, n in counts.items():
    print(f"{old} -> remplacé {n} fois")

p.write_text(text, encoding="utf-8")
```

Vérifier que chaque compteur affiché est cohérent avec ce qui a été vu dans le registre (au moins quelques occurrences pour chacun — pas 0). Ne pas committer ce changement seul : il sera inclus dans le commit de la Phase 2 ci-dessous (registre + correctif C173 ensemble), pour garder un historique lisible.

**Note pour la traçabilité :** les commits déjà existants `2658caf` (ex-C161), `fd80fca` (ex-C162), `645f942` (ex-C163) gardent leurs messages d'origine (git ne réécrit pas l'histoire) — le registre renuméroté doit le signaler explicitement, par exemple en ajoutant entre parenthèses après chaque titre de ticket renuméroté : *« anciennement C161, commit `2658caf` — numéro entré en collision avec le module support/ de `main`, renuméroté C170 le 26/09/2026 »* (adapter pour chacun des 6).

---

## Phase 2 — Correctif C173 (doublon de providers) + ticket registre, sur `consolidation-wip-20260921`

Dans `lib/app.dart`, section `MultiProvider` : les 3 lignes suivantes apparaissent deux fois consécutivement (vérifier avec `grep -n "AuthProvider()\|DashboardProvider()\|SearchProvider()" lib/app.dart` — doit remonter 6 lignes avant correctif, 3 après) :

```dart
ChangeNotifierProvider(create: (_) => AuthProvider()),
ChangeNotifierProvider(create: (_) => DashboardProvider()),
ChangeNotifierProvider(create: (_) => SearchProvider()),
```

Supprimer la **seconde** occurrence des 3 lignes (garder la première, ne rien changer d'autre autour).

Ajouter au registre (`docs/PharmaConnect_Registre_Ecarts_A_Verifier.md`), à la suite de l'entrée C166, une entrée **C173** :

```markdown
**C173 — résolu le 26/09/2026** — `lib/app.dart` : `AuthProvider()`, `DashboardProvider()` et `SearchProvider()` étaient chacun déclarés deux fois dans le `MultiProvider` (doublon sans impact fonctionnel constaté — Provider retient la première instance déclarée — mais dette cosmétique). Découvert en vérifiant la fiabilité du code à l'occasion de la réconciliation `main`/`consolidation-wip-20260921` du 26/09/2026, corrigé en supprimant la seconde occurrence. Voir aussi **D54** (décision de réconciliation des branches).
```

Ajouter aussi une entrée **D54** (décision, pas dette technique) résumant la réconciliation :

```markdown
**D54 — Réconciliation `main` / `consolidation-wip-20260921` (26/09/2026)** — vérification croisée demandée par le porteur du projet ayant révélé que `main` avait déjà récupéré, le 22/09/2026, les Modules 1-29 depuis `consolidation-wip-20260921` (protocole `reconciliation(...)`, un commit par module), à l'exception du cluster hors-cahier `business/pos/sales/cash/returns` (en cours d'audit sur cette session, C150-C166) et du cluster IA/forecast (Module 11, différé des deux côtés, C165). Collision de numérotation détectée sur **C158-C163** avec un module `support/` construit indépendamment sur `main` (commits `2bcf275`/`c37e7f2`/`55b0edc`) : décision du porteur du projet, nos 6 tickets sont renumérotés **C167-C172** (voir en-tête de chaque ticket concerné), les tickets support/ de `main` ne sont pas touchés. Le cluster hors-cahier restant est ensuite réconcilié sur `main` selon le même protocole déjà en place (un commit par module).
```

Committer Phase 1 + Phase 2 ensemble, un seul commit, fichiers listés explicitement :
`fix(app): remove duplicate provider declarations (C173) + renumber C158-C163 to C167-C172 in registre (D54)`

---

## Phase 3 — Bascule sur `main` et restauration du cluster hors-cahier

```bash
git checkout main
```

Pour chacun des modules suivants, restaurer l'ensemble de ses fichiers **tels qu'ils existent sur `consolidation-wip-20260921` après la Phase 2** (donc après le renumérotage), avec un commit dédié par module, même formulation que le 22/09 (`reconciliation(<module>): restaure cluster hors-cahier <NOM> depuis consolidation-wip-20260921`) :

1. **`business/`** — `lib/modules/business/**`
2. **`pos/`** — `lib/modules/pos/**`, plus `lib/core/services/offline_sales_service.dart`
3. **`sales/`** — `lib/modules/sales/**` (attention : exclure tout fichier qui importerait `demand_prediction.dart`/`price_recommendation.dart`/`fraud_alert.dart`/`product_recommendation.dart` ou qui en dépendrait — cluster IA, ticket **C165**, toujours hors périmètre, à ne PAS restaurer maintenant)
4. **`cash/`** — `lib/modules/cash/**`
5. **`returns/`** — `lib/modules/returns/**`

Méthode par module (exemple pour `business/`) :
```bash
git checkout consolidation-wip-20260921 -- lib/modules/business/
git add lib/modules/business/
git commit -m "reconciliation(business): restaure cluster hors-cahier BUSINESS depuis consolidation-wip-20260921"
```
Répéter pour chaque module de la liste, en adaptant le chemin et le message.

**Migrations Supabase associées**, restaurer aussi (dans un commit `reconciliation(migrations): restaure migrations hors-cahier business/pos/sales/cash/returns depuis consolidation-wip-20260921`) — vérifier au préalable avec `git diff main consolidation-wip-20260921 -- supabase/migrations/` que chaque fichier ci-dessous concerne bien ce cluster et pas le cluster IA/forecast (celui-ci reste différé) :
- `20260829003800_admin_helpers.sql` (si lié au cluster hors-cahier — vérifier son contenu avant de l'inclure)
- `20260829004000_business.sql`
- `20260829006000_pos.sql`, `20260829006000_pos_and_network_admin.sql`
- `20260829008000_sales.sql`, `20260829008000_sales_management.sql`
- `20260829009000_cash.sql`
- `20260829010000_returns.sql`
- `20260829012000_offline_sales.sql`
- Exclure explicitement `20260829011000_sales_ai.sql` et `20260829022000_forecasting_module_fixes.sql` (cluster IA/forecast, C165, différé) — ne pas les restaurer.
- Les fichiers `20260827008500_loyalty.sql`, `20260828015000_loyalty_ai.sql`, `20260829043000_loyalty_module_fixes.sql` : vérifier d'abord s'ils font doublon avec des migrations déjà présentes sur `main` (Module 16/FID a déjà été réconcilié le 22/09) avant de les copier — ne les ajouter que s'ils apportent un schéma réellement absent de `main`.

## Phase 4 — Câblage `app.dart` et `app_router.dart`

**`lib/app.dart`** — ajouter les imports et déclarations manquants pour `BusinessProvider`, `POSProvider`, `SalesProvider`, `CashProvider`, `ReturnsProvider`, `OfflinePOSProvider` (déjà présents sur `consolidation-wip-20260921`, absents de `main`), en suivant exactement le style des commits `reconciliation(app-wiring)` déjà faits le 22/09 (commentaire expliquant l'oubli si un écran les utilisait déjà). Un commit dédié : `reconciliation(app-wiring): cable business, pos, sales, cash, returns dans app.dart`.

**`lib/routes/app_router.dart`** — `main` a déjà toute la structure d'imports commentés avec `// TODO PharmaConnect: écran non cadré, cluster hors-cahier...` pour les écrans pas encore construits. Pour chaque écran du cluster hors-cahier qui **existe réellement** sur `consolidation-wip-20260921` (vérifier avec `git cat-file -e consolidation-wip-20260921:<chemin>` avant de décommenter quoi que ce soit), décommenter son import et sa `GoRoute` correspondante. À ce stade, cela concerne au moins : `cash_history_screen.dart`, `cash_report_screen.dart`, `customer_return_detail_screen.dart`, `customer_return_create_screen.dart`, `company_create_screen.dart` (et `company_edit_screen.dart` si présent). Les écrans `sales/` de niveaux 2-4 (`customer_detail`, `customer_create`, `suppliers_list`, `orders_list`, `quotations_list`, `invoices_list`) n'existent pas encore (C164 lots 2/3 et 3/3 pas encore traités) — laisser leurs imports/routes commentés, ne rien décommenter pour eux. Un commit dédié : `reconciliation(routes): decommente les routes hors-cahier deja construites (cash, returns, business)`.

## Phase 5 — Documentation

Copier `docs/PharmaConnect_Registre_Ecarts_A_Verifier.md` (version Phase 2, déjà renumérotée) et `STRUCTURE_PROJET.md` depuis `consolidation-wip-20260921` vers `main` :
```bash
git checkout consolidation-wip-20260921 -- docs/PharmaConnect_Registre_Ecarts_A_Verifier.md STRUCTURE_PROJET.md
git add docs/PharmaConnect_Registre_Ecarts_A_Verifier.md STRUCTURE_PROJET.md
git commit -m "docs: synchronise le registre d'ecarts et la structure projet sur main"
```

## Phase 6 — Vérification

1. `flutter analyze lib/` — donner le total exact, comparer au dernier total connu sur `consolidation-wip-20260921` (134 après C166 ; C164 lot 1 pas encore vérifié en analyse complète).
2. `flutter test` — donner le résultat exact (nombre de tests passés/échoués), comparer au dernier total connu (72/28).
3. `git diff main-avant-reconciliation-hors-cahier-20260926 main --stat` — pour avoir la liste complète et le total de fichiers touchés, à coller dans le rapport.
4. Ne PAS supprimer `consolidation-wip-20260921` ni `pre-consolidation-20260921-safety` ni la branche de sécurité — elles restent comme filet tant que la réconciliation n'est pas validée.

---

## Rapport attendu en retour

Pour chaque commit créé (un par module + app-wiring + routes + docs) : hash + message + nombre de fichiers touchés. Plus : les 6 comptes de remplacement de la Phase 1 (`C158 -> N fois`, etc.), confirmation du doublon supprimé dans `app.dart`, le résultat exact de `flutter analyze lib/` et `flutter test`, et la liste de tout fichier de migration finalement **exclu** par prudence (avec la raison). Je vérifie chaque commit par lecture directe (`git show`) avant de considérer C167-C173 comme clos et D54 comme actée.

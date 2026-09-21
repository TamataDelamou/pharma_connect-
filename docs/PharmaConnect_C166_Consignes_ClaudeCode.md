# C166 — `GlassCard(margin:)` : paramètre inexistant sur 2 écrans (`sales`/`returns`)

**Rédigé par :** session d'audit (Cowork). Découvert en marge de la vérification du diff C163 — le rapport d'exécution citait cette erreur comme « même motif que C155 », ce qui est inexact (C155 concerne le chaînage Postgrest + l'import `ReturnReason` de `returns_service.dart`, sans rapport). Diagnostic vérifié par lecture directe, aucune investigation supplémentaire requise.
**Destinataire :** Claude Code, exécuté localement avec `flutter`/`dart` installés.
**Date :** 21/09/2026
**Contexte :** `GlassCard` (`lib/core/widgets/cards/glass_card.dart`) n'a jamais eu de paramètre `margin` — son constructeur n'expose que `child`, `padding`, `borderRadius`, `glow`, `glowColor`, `onTap`, `hoverEffect` (vérifié en lisant le fichier en entier). Deux écrans lui passent pourtant `margin: const EdgeInsets.only(bottom: 8)`, erreur de compilation identique dans les deux : `lib/modules/sales/screens/customers_list_screen.dart` et `lib/modules/returns/screens/customer_returns_list_screen.dart`. Explique très probablement l'ancien foyer « `returns` 2 erreurs » du registre, jamais détaillé jusqu'ici. Le motif de correction est déjà établi et fonctionnel ailleurs dans ce dépôt : `lib/modules/cash/screens/cash_history_screen.dart` (écran niveau 1, vérifié sain) enveloppe chaque `GlassCard` d'un `Padding` plutôt que de lui passer un `margin` — reproduire exactement ce motif, rien d'autre.

---

## 0. Périmètre

2 fichiers, aucun autre :
- `lib/modules/sales/screens/customers_list_screen.dart`
- `lib/modules/returns/screens/customer_returns_list_screen.dart`

Ne rien toucher d'autre. En particulier ne pas toucher `lib/core/widgets/cards/glass_card.dart` (pas question d'ajouter un paramètre `margin` au widget partagé — le motif « envelopper dans un `Padding` » est déjà celui utilisé ailleurs dans ce dépôt, à reproduire tel quel, pas à contourner autrement).

## 1. `lib/modules/sales/screens/customers_list_screen.dart`

Dans le `ListView.builder` de la liste des clients (`itemBuilder`), le `GlassCard` retourné directement porte un `margin:` invalide :

Avant :
```dart
                      itemBuilder: (context, index) {
                        final customer = provider.customers[index];
                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 8),
                          onTap: () =>
                              context.push('/sales/customer/${customer.id}'),
                          child: Row(
                            children: [
                              CircleAvatar(
```
*(le `child: Row(...)` continue sur plusieurs dizaines de lignes, ne pas y toucher)*

Après — seuls 3 changements : (a) `return GlassCard(` devient `return Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassCard(`, (b) la ligne `margin: const EdgeInsets.only(bottom: 8),` est supprimée, (c) la parenthèse fermante correspondant à ce `GlassCard(` (celle qui suit la fin de son `child: Row(...)`, donc après le `)` qui ferme la `Row` — actuellement une ligne `);` isolée) devient `),);` pour fermer à la fois `GlassCard(` et le nouveau `Padding(` :

```dart
                      itemBuilder: (context, index) {
                        final customer = provider.customers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () =>
                                context.push('/sales/customer/${customer.id}'),
                            child: Row(
                              children: [
                                CircleAvatar(
```
*(tout le contenu interne du `Row(...)` garde exactement le même contenu et la même logique — seule l'indentation change d'un niveau puisqu'il y a désormais un widget de plus autour ; laisser `dart format` ou l'IDE réindenter, ne rien modifier au fond)*

... jusqu'à la parenthèse fermante finale du `GlassCard`, qui doit devenir :
```dart
          ),
        );
```
(fermeture de `GlassCard(` puis de `Padding(`, au lieu d'une seule fermeture de `GlassCard(` avant).

## 2. `lib/modules/returns/screens/customer_returns_list_screen.dart`

Même défaut, même correctif, dans le `ListView.builder` de la liste des retours clients :

Avant :
```dart
    return ListView.builder(
      itemCount: provider.customerReturns.length,
      itemBuilder: (context, index) {
        final returnData = provider.customerReturns[index];
        return GlassCard(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          onTap: () => context.push('/returns/customer/${returnData.id}'),
          child: Row(
            children: [
              Container(
```

Après (même principe qu'en section 1 — `return GlassCard(` → `return Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassCard(`, suppression de la ligne `margin:`, fermeture finale `),);` à la place de `);`) :

```dart
    return ListView.builder(
      itemCount: provider.customerReturns.length,
      itemBuilder: (context, index) {
        final returnData = provider.customerReturns[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push('/returns/customer/${returnData.id}'),
            child: Row(
              children: [
                Container(
```

## 3. Vérification et commit

1. `dart format lib/modules/sales/screens/customers_list_screen.dart lib/modules/returns/screens/customer_returns_list_screen.dart` — pour réindenter proprement après l'ajout d'un niveau de widget, sans risquer une erreur de frappe manuelle sur l'indentation.
2. `flutter analyze lib/modules/sales/screens/customers_list_screen.dart lib/modules/returns/screens/customer_returns_list_screen.dart` — doit confirmer 2 erreurs corrigées (1 par fichier), aucune nouvelle.
3. Puis `flutter analyze lib/` et `flutter test` complets, pour confirmer qu'aucune régression n'a été introduite ailleurs et obtenir le nouveau total (dernier connu : 136 erreurs après C163, ce correctif doit le réduire d'environ 2 — confirmer le chiffre exact, ne pas supposer).
4. Un seul commit, fichiers listés explicitement (pas de `git add -A`) :
   `fix(sales,returns): replace invalid GlassCard margin with Padding wrapper (C166)`

## 4. Décisions de règle métier remontées (à remplir par Claude Code en cours de route)

*(Section à compléter uniquement si un point de règle métier apparaît en cours de correctif — ne pas trancher, décrire et attendre l'arbitrage du porteur du projet.)*

---

**Rapport attendu en retour :** confirmation du diff appliqué (ou explication précise si un point ne correspond pas à ce qui est décrit ci-dessus), + nombre d'erreurs `flutter analyze lib/` avant/après, + résultat `flutter test`. Je mets à jour le registre (C166 → résolu) une fois ce retour vérifié.

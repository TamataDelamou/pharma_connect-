# PharmaConnect — Protocole de test E2E, Module 8 (PAY)

**Date :** 29/08/2026
**Objet :** Valider en conditions réelles (base Supabase de test + appareil/émulateur) les correctifs du Module 8, en particulier le câblage réel du parcours d'achat vers PAY. Non exécuté dans cette session (pas d'accès Flutter SDK/émulateur ni de projet Supabase de test depuis le pont machine actuel — voir A1/A16 du registre des écarts). À exécuter par le porteur du projet ou une équipe QA outillée.

**Prérequis communs à tous les scénarios :**
- Projet Supabase de test avec les migrations à jour, y compris `20260829019000_payments_module_fixes.sql`.
- Au moins deux comptes patient et un compte pharmacien avec `pharmacy_id` renseigné.
- Application installée sur appareil réel ou émulateur (le pont machine actuel n'y donne pas accès).

---

## Scénario 1 — Achat complet, bout en bout (le plus important)

**Objectif :** confirmer que le correctif central du module (checkout → paiement réel) fonctionne de bout en bout.

1. Se connecter en tant que patient A.
2. Ajouter des produits au panier, aller jusqu'au checkout (`reservation_checkout_screen.dart`).
3. Choisir un créneau, saisir une adresse de livraison, cocher "Livraison chaîne du froid" si pertinent.
4. À l'étape Paiement, choisir "Orange Money", cliquer "Confirmer la commande".
5. **Attendu :** la réservation est créée ; un SnackBar de succès ou d'échec de paiement peut apparaître (non bloquant) ; la livraison est programmée si une adresse a été saisie ; l'écran de confirmation s'affiche avec le QR code.
6. **Vérification base de données :**
   - `select * from transactions where reservation_id = '<id de la réservation>'` → une ligne, `method = 'orangeMoney'`, `status = 'completed'` après ~2s, `pharmacy_id` renseigné (pas null).
   - `select * from invoices where transaction_id = '<id>'` → une ligne générée.
   - `select * from deliveries where reservation_id = '<id>'` → une ligne si une adresse a été saisie.
7. Ouvrir `/transactions` (historique) → la transaction apparaît avec le bon montant et statut.

## Scénario 2 — Paiement par portefeuille GSG, solde suffisant

1. Recharger le portefeuille du patient A de 50 000 GNF via `/wallet` → "Approvisionner".
2. Vérifier en base : `select balance from wallets where user_id = '<id patient A>'` → 50 000.
3. Effectuer un achat de 20 000 GNF via checkout avec "Portefeuille GSG".
4. **Attendu :** transaction `completed`, aucun message d'erreur de solde.
5. **Vérification :** `wallets.balance` a diminué du montant exact payé (`final_amount`, frais compris — gsgWallet a `fee = 0` donc `final_amount = amount - cashback éventuel`).

## Scénario 3 — Paiement par portefeuille GSG, solde insuffisant

1. Portefeuille à 5 000 GNF.
2. Tenter un achat de 20 000 GNF avec "Portefeuille GSG" depuis `/payments` (écran dédié, plus simple à isoler pour ce test).
3. **Attendu :** message d'erreur explicite ("Solde du portefeuille GSG insuffisant pour ce paiement."), aucune transaction créée, aucun débit.
4. **Vérification :** `wallets.balance` inchangé ; `select count(*) from transactions where user_id = '<id>' and method = 'gsgWallet' and created_at > '<horodatage du test>'` → 0.

## Scénario 4 — Cashback plafonné au solde réel

1. Portefeuille avec `cashback_available = 500` GNF (via SQL direct si besoin, pas de flux UI pour créditer manuellement).
2. Achat de 100 000 GNF en Orange Money avec la case "Utiliser mon cashback" cochée (le calcul UI affiche 2% = 2 000).
3. **Attendu :** le montant réellement déduit est plafonné à 500 GNF, pas 2 000.
4. **Vérification :** `transactions.cashback = 500` (pas 2000) sur la ligne créée ; `wallets.cashback_available = 0` après la transaction (500 dépensés, éventuellement re-crédité si la méthode gagne du cashback — voir scénario 5).

## Scénario 5 — Cashback gagné après une transaction complétée

1. Portefeuille à `cashback_available = 0`.
2. Achat de 100 000 GNF en MTN MoMo (méthode mobile money → gagne 2% = 2 000), sans cocher "Utiliser mon cashback".
3. **Attendu :** après complétion (~2s), `wallets.cashback_available` passe de 0 à 2 000.
4. **Vérification :** `select cashback_available, total_earned from wallets where user_id = '<id>'` avant/après.

## Scénario 6 — Paiement en plusieurs fois (échéancier)

1. Achat de 90 000 GNF via `/payments` avec "Paiement en plusieurs fois", sélectionner "3 fois".
2. **Attendu :** redirection vers `/payments/installment/<id transaction>`, l'écran affiche un échéancier avec 3 échéances de 30 000 GNF, "0/3" payées. **Ne doit plus afficher "Aucun échéancier trouvé".**
3. Payer la 1ère puis la 2ème échéance → compteur progresse (1/3, 2/3), transaction parente reste `processing`.
4. Payer la 3ème (dernière) échéance.
5. **Attendu :** l'échéancier passe à `completed`, ET la transaction parente passe à `completed` avec une facture générée.
6. **Vérification :** `select status from transactions where id = '<id>'` → `completed` ; `select * from invoices where transaction_id = '<id>'` → une ligne.

## Scénario 7 — Premier accès portefeuille (auto-provisionnement)

1. Créer un nouveau compte patient jamais encore allé sur `/wallet` ou `/payments`.
2. Ouvrir `/wallet`.
3. **Attendu :** aucune exception, le portefeuille s'affiche avec un solde de 0 (pas d'erreur "no rows returned").
4. **Vérification :** `select * from wallets where user_id = '<nouveau patient>'` → une ligne existe désormais, créée automatiquement.

## Scénario 8 — Litige : description non perdue

1. Depuis `/disputes`, sélectionner une transaction complétée.
2. Saisir une raison ("Paiement non reconnu") et une description détaillée ("Le prélèvement apparaît deux fois sur mon relevé Orange Money du 28/08").
3. Soumettre.
4. **Vérification :** `select notes from transactions where id = '<id>'` → contient bien les deux textes saisis (raison ET description), pas seulement la raison.

## Scénario 9 — Réconciliation pharmacie : contrôle d'accès et portée

1. Se connecter en tant que patient (rôle non pharmacien) et tenter d'accéder à `/pharmacy/reconciliation`.
2. **Attendu :** écran bloqué, message "Réservé aux pharmaciens de l'officine."
3. Se connecter en tant que pharmacien de l'officine X, avoir au moins une transaction de l'officine Y (autre officine) en base créée par un autre patient.
4. Ouvrir `/pharmacy/reconciliation`.
5. **Attendu :** seules les transactions de l'officine X apparaissent, jamais celles de l'officine Y.

## Scénario 10 — Blocage explicite du paiement hors connexion (décision D13)

1. Sur un appareil réel (pas un émulateur sans capteur réseau fiable), désactiver Wi-Fi et données mobiles.
2. Depuis `/payments`, tenter de payer.
3. **Attendu :** message immédiat "Paiement indisponible hors connexion...", aucun appel réseau tenté, aucune transaction en `pending` orpheline créée.
4. Répéter depuis `/wallet` → "Approvisionner" → "Recharger" : même comportement attendu.
5. Répéter depuis le checkout (`reservation_checkout_screen.dart`, étape Paiement) : **la réservation doit tout de même être créée** (mode hors-ligne RES déjà en place), mais un message distinct doit indiquer que le paiement devra être réglé une fois reconnecté.

## Scénario 11 — Mode hors-ligne en lecture (solde, historique)

1. Charger `/wallet` et `/transactions` une première fois en ligne (pour peupler le cache).
2. Couper la connexion, redémarrer l'app ou revenir sur ces écrans.
3. **Attendu :** le dernier solde/historique synchronisé s'affiche quand même, avec une bannière "Hors connexion — dernières données synchronisées affichées".
4. (Voir A16 du registre : ce scénario n'a jamais été exercé de bout en bout, à confirmer en priorité.)

## Scénario 12 — Non-régression RLS (écriture)

1. Avec un compte patient authentifié, tenter directement via l'API REST Supabase (ex. `curl`/Postman avec le JWT du patient) une insertion dans `transactions` avec un `user_id` différent du sien.
2. **Attendu :** refusé par RLS (`transactions_insert_own` exige `auth.uid() = user_id`).
3. Tenter une lecture de `transactions` d'un autre patient sans lien de pharmacien.
4. **Attendu :** refusé par RLS (aucune ligne retournée, sauf si l'utilisateur est aussi `is_pharmacy_staff` de la pharmacie concernée).

---

## Rapport à produire après exécution

Pour chaque scénario : ✅ conforme / ❌ écart constaté (avec capture ou requête SQL à l'appui) / ⏭️ non exécuté (avec raison). Ce rapport rempli devient la pièce justificative du PV de recette du Module PAY.

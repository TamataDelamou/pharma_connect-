# PharmaConnect — Essai court de la version « release »

**Pour qui :** Achille, avec les deux téléphones et les comptes de l'essai du lot 3.
**État :** guide préparé le 12/10/2026, après la fusion des quatre branches du plan de correction. Rien n'a encore été joué sur un téléphone.
**Durée :** environ 45 minutes.
**But :** reprouver sur appareil, avec la version « release », les points « à prouver sur appareil » de C253 à C258, C260 et C261, la permission Internet de C248 et le scan du QR code.

---

## 0. À lire avant de commencer

**L'application parle à la production**, comme pendant l'essai du lot 3 : tout ce que vous faites est réel. Ne réservez et ne vendez que dans l'officine « TEST Officine Lot 3 ».

**Ce qui change par rapport à la version d'essai (« debug ») :**

- Un écran qui déborde n'affiche plus de bandeau rayé jaune et noir : le contenu est simplement coupé. Pour C253 et C257, regardez donc si **un texte, un bouton ou un montant est coupé au bord de l'écran**.
- L'application est plus légère et plus rapide.

**La vente au comptoir ajoute toujours 5 % de TVA** (C259, en attente de votre décision). Une boîte à 1 500 GNF est encaissée 1 575 GNF au comptoir, et 1 500 GNF au retrait d'une réservation. Les montants attendus de ce guide en tiennent compte.

**En cas d'écart, à chaque étape :** une capture d'écran, l'heure, le téléphone (A ou B) et le compte. Ne pas insister : noter, puis continuer si l'étape suivante n'en dépend pas.

| Élément | Rôle |
|---|---|
| Téléphone A | l'officine, compte « pharmacien » (`delamoutamata+pharmacien2@gmail.com`) |
| Téléphone B | le patient (`delamoutamata+patient@gmail.com`) |

---

## 1. Installation (C248)

1. Copiez `PharmaConnect-release-95ba22b.apk` sur les deux téléphones.
2. Ouvrez le fichier et installez. Il remplace la version d'essai : vos comptes restent.
3. **Si l'installation est refusée** (« application non installée », conflit de signature) : notez le message, désinstallez l'ancienne version, puis réinstallez.

**Vous devez voir :** l'écran « Connexion », ou le tableau de bord si la session a été gardée.

---

## 2. Connexion et tableau de bord (C248, C261)

Sur chaque téléphone :

1. Si l'écran « Connexion » s'affiche : saisissez l'adresse du compte, puis le code reçu par e-mail.
2. **Vous devez voir :** le tableau de bord. C'est la preuve que la version « release » joint le serveur (permission Internet, C248).
3. Tirez le tableau de bord vers le bas, puis relâchez.

**Vous devez voir :** une roue d'actualisation en haut de l'écran pendant une à deux secondes, puis elle disparaît. Le tableau de bord reste affiché pendant ce temps.

---

## 3. Téléphone A : ouverture de la caisse (C258, C253)

1. Menu ☰ → « Ouverture de caisse ».
2. Si une caisse est déjà ouverte, fermez-la d'abord (montant compté = solde attendu affiché).
3. « Ouvrir la caisse » → fond de caisse : `10000` → « Ouvrir ».

**Vous devez voir :**

- « Fonds de caisse 10000 GNF » et, dans « Résumé », **« Solde attendu 10000 GNF »** (C258 : avant, 0 ou une valeur figée).
- Les trois boutons « Rapport », « Historique » et « Fermer la caisse » **l'un sous l'autre, sur toute la largeur, lisibles en entier** (C253 : avant, « F… »).

Laissez la caisse ouverte.

**Avant d'aller plus loin**, ouvrez « Stock & Lots » et vérifiez le point de départ : Paracétamol, 8 boîtes, 0 réservée (constaté le 12/10/2026). S'il est différent, notez-le : il sert au contrôle de la section 11.

---

## 4. Téléphone B : recherche (C260, C261, C253)

1. Menu ☰ → « Recherche ». S'il reste des lettres isolées dans l'historique (« p », « pa »…), elles datent de l'ancien essai : touchez « Effacer ».
2. Tapez `paracetamol` lettre par lettre, à vitesse normale, **sans valider au clavier**. Attendez les résultats.
3. Effacez le texte avec la croix. **Vous devez voir :** l'historique ne contient **aucune** de ces lettres (« p », « pa », « par »…).
4. Tapez de nouveau `paracetamol`, puis touchez la loupe « Rechercher » du clavier.
5. Effacez le texte avec la croix. **Vous devez voir :** l'historique contient `paracetamol`, une seule fois.
6. Touchez `paracetamol` dans l'historique : les résultats reviennent.
7. Tirez la liste des résultats vers le bas. **Vous devez voir :** la roue d'actualisation, la liste toujours affichée.
8. Regardez les cartes de résultat : **aucun texte coupé au bord droit** ; un long nom d'officine se termine par « … » à l'intérieur de la carte.

---

## 5. Téléphone B : une seule boîte au panier (C254), réservation n° 1

1. Ouvrez la fiche « Paracétamol ». Regardez la ligne « TEST Officine Lot 3 » : « Ouvert », la distance et le prix tiennent dans la ligne.
2. Touchez la ligne « TEST Officine Lot 3 ». **Vous devez voir :** le panier, 1 boîte.
3. Revenez en arrière **sans commander**. Touchez de nouveau la ligne « TEST Officine Lot 3 ».
4. Recommencez une troisième fois.

**Vous devez voir, à chaque fois :** le panier avec **1 boîte**, jamais 2 ni 3 (C254).

5. Dans le panier, appuyez sur « + » pour passer à `2`. « Passer la commande » → « Confirmer la commande ».

**Vous devez voir, sur l'écran de validation :**

- Le **QR code noir sur fond blanc**, bien net, avec une marge blanche autour (C256 : avant, noir sur presque noir).
- « Position dans la file » et « Temps d'attente estimé » côte à côte, **lisibles en entier** (C253).
- « Voir l'historique » et « Retour à l'accueil » l'un sous l'autre, lisibles en entier (C253).

**Notez le code n° 1. Restez sur cet écran** pour l'étape 6.

---

## 6. Scan du QR code depuis l'écran de validation (C256, C248)

Téléphone A :

1. Menu ☰ → « File des réservations » → « Retrait » sur la réservation du patient.
2. Touchez l'icône de QR dans le champ « Code de retrait du patient ». Android demande l'accès à l'appareil photo : acceptez (C248 : l'appareil photo fonctionne en version « release »).
3. Visez le QR code affiché sur le téléphone B.

**Vous devez voir :** le code se remplit tout seul, identique au code n° 1.

4. « Encaisser et remettre ». **Vous devez voir :** « Retrait enregistré », puis le reçu : **3 000 GNF**, espèces, sans TVA.
5. Sur le reçu, regardez les boutons « Imprimer », « Partager » et « Rembourser » : **l'un sous l'autre, lisibles en entier** (C253).

**Si le scan échoue :** notez-le (capture, heure, luminosité de l'écran du téléphone B), puis saisissez le code à la main pour continuer.

---

## 7. Téléphone B : réservation n° 2, QR code depuis la liste (C255, C261)

1. Refaites une réservation de 1 boîte de Paracétamol dans l'officine TEST. **Notez le code n° 2.** Quittez l'écran de validation.
2. Menu ☰ → « Réservations ». Touchez la carte de la réservation n° 2.

**Vous devez voir :** une fine barre de progression au-dessus de la liste, la liste toujours affichée, puis l'écran « QR code de retrait » avec le code n° 2 (C255 : avant, rien ne s'ouvrait).

3. Revenez à la liste. Touchez la carte **deux fois très vite**. **Vous devez voir :** un seul écran de QR code ; un seul retour ramène à la liste.
4. Téléphone A : « File des réservations » → « Prête » sur la réservation n° 2.
5. Téléphone B : dans « Réservations », tirez la liste vers le bas. **Vous devez voir :** la roue d'actualisation, puis la réservation à l'état « prête » (C261).
6. Touchez la carte. **Vous devez voir :** le QR code, état « Prête ».

### 7.1 Hors connexion

1. Téléphone B : revenez à la liste, puis activez le **mode avion**.
2. Touchez la carte de la réservation n° 2.

**Vous devez voir :** l'écran du QR code, avec le code n° 2 et la mention « Hors connexion — dernières données enregistrées. L'état et l'échéance affichés sont les derniers connus. »

3. **Laissez le mode avion activé** et gardez cet écran pour l'étape 8.

---

## 8. Scan du QR code depuis la liste, téléphone B hors connexion (C256, C255)

Téléphone A (connecté) : « File des réservations » → « Retrait » sur la réservation n° 2 → icône de QR → visez le téléphone B.

**Vous devez voir :** le code n° 2 rempli tout seul. « Encaisser et remettre » → reçu de **1 500 GNF**.

Téléphone B : **désactivez le mode avion**. Dans « Réservations », tirez pour actualiser, onglet « Terminées » : les deux réservations sont « retirées ».

---

## 9. Téléphone A : vente au comptoir (C257)

1. Tableau de bord → « Caisse » (vente au comptoir).

**Vous devez voir :**

- Une seule colonne : la recherche, le bouton « Rechercher » sur toute la largeur, les produits du stock, « Panier », puis « Résumé » en faisant défiler.
- En bas de l'écran, **toujours visibles** : « À payer » avec le montant en entier, et le bouton « Finaliser la vente » sur toute la largeur.
- Aucun texte coupé au bord droit (avant : « Recher… », « Pa… », « Résumé » coupé).

2. Touchez « Paracétamol » dans la liste. **Vous devez voir :** le panier avec 1 boîte, « À payer 1575 GNF » (1 500 + 5 % de TVA, C259).
3. Faites défiler jusqu'à « Résumé » : « Total 1500 GNF », « TVA (5%) 75 GNF », « Mode de paiement : Espèces », « Vider le panier » lisible en entier.
4. « Finaliser la vente ». **Vous devez voir :** le reçu, 1 575 GNF.

---

## 10. Téléphone A : solde attendu et fermeture de la caisse (C258)

1. Menu ☰ → « Ouverture de caisse ».

**Vous devez voir, dans « Résumé » :** « Ventes 6075 GNF » et **« Solde attendu 16075 GNF »**.

Le calcul : fonds 10 000 + retrait n° 1 3 000 + retrait n° 2 1 500 + vente au comptoir 1 575 = 16 075.

2. « Fermer la caisse ». **Vous devez voir, dans le message :** « Solde attendu : 16075 GNF », le même chiffre qu'à l'écran.
3. Solde réel : `16075` → « Fermer ».

**Vous devez voir :** « Caisse fermée avec succès ».

**Contrôle de ma part, si vous le souhaitez :** session fermée, attendu 16 075, compté 16 075, écart 0.

---

## 11. Téléphone A : contrôle du stock

Menu ☰ → « Stock & Lots ».

**Vous devez voir :** Paracétamol, **4 boîtes, 0 réservée**.

Le calcul : 8 boîtes au départ (constaté le 12/10/2026), moins 2 pour le retrait n° 1, 1 pour le retrait n° 2 et 1 pour la vente au comptoir. Chaque boîte est sortie du stock une seule fois, et plus aucune n'est retenue.

**Si le chiffre de départ n'est plus 8** (une vente ou une réservation faite entre-temps) : notez le stock avant de commencer l'essai ; il doit avoir baissé de 4 à la fin, avec 0 réservée.

---

## 12. Ce que cet essai ne couvre pas

- **Le QR code de l'écran « Réservation confirmée »** : cet écran ne s'ouvre qu'après un paiement en ligne, masqué pendant le pilote. Il utilise le même composant que les deux autres, mais il ne peut pas être scanné ici.
- **La lecture de la position de l'officine** (C252) en version « release » : elle ne se joue qu'à la candidature d'une nouvelle officine, donc avec un nouveau compte pharmacien. À jouer à part si vous le voulez.
- **La TVA** (C259) : aucun changement, votre décision est attendue.
- **La signature de publication** : cette version est signée avec la clé d'essai. Elle s'installe à la main, elle ne peut pas être publiée sur le Play Store.

---

## 13. Relevé à me rendre

| # | Point | Écart | Conforme ? |
|---|---|---|---|
| 1 | Installation par-dessus la version d'essai | C248 | |
| 2 | Connexion au serveur, téléphones A et B | C248 | |
| 3 | Tableau de bord : roue d'actualisation | C261 | |
| 4 | Caisse : solde attendu 10 000 à l'ouverture | C258 | |
| 5 | Caisse : trois boutons lisibles en entier | C253 | |
| 6 | Historique sans lettres isolées | C260 | |
| 7 | Historique après validation au clavier | C260 | |
| 8 | Recherche : roue d'actualisation | C261 | |
| 9 | Cartes de résultat et ligne d'officine non coupées | C253 | |
| 10 | Une seule boîte après trois retours | C254 | |
| 11 | QR code lisible sur l'écran de validation | C256 | |
| 12 | Écran de validation : position et boutons lisibles | C253 | |
| 13 | Scan depuis l'écran de validation | C256, C248 | |
| 14 | Reçu de vente : trois boutons lisibles | C253 | |
| 15 | QR code ouvert depuis « Réservations » | C255 | |
| 16 | Double toucher : un seul écran | C255 | |
| 17 | « Réservations » : roue d'actualisation, état « prête » | C261 | |
| 18 | QR code ouvert hors connexion, avec la mention | C255 | |
| 19 | Scan depuis l'écran du QR code | C256 | |
| 20 | Vente au comptoir : une colonne, « À payer » visible | C257 | |
| 21 | Solde attendu 16 075 à l'écran et dans le message | C258 | |
| 22 | Fermeture : écart 0 | C258 | |
| 23 | Stock : Paracétamol à 4 boîtes, 0 réservée | stock | |

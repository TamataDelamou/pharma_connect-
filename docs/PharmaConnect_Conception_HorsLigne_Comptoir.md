# PharmaConnect — Note de conception : vente au comptoir hors ligne (C239, partie B)

**Statut :** validée le 04/10/2026 par Achille, avec les sept décisions reportées en fin de note. Aucun code du hors-ligne n'est encore écrit : l'étape 1 ne commence qu'après la correction et la validation de C240 (lot rappelé vendu en ligne).
**Date :** 04/10/2026.
**Lié à :** registre, lignes C239 et C240, point A35 ; reprend le chantier C195 (vente hors ligne retirée par C191).

## Ce qui est décidé (Achille, 04/10/2026)

- Le hors-ligne est obligatoire pour l'officine pendant le pilote.
- Il est limité à la **vente au comptoir, en espèces uniquement**.
- Retours et remboursements : **en ligne seulement**.
- **Bandeau d'avertissement dès 12 h** sans synchronisation, **blocage de la vente après 24 h**.
- Principe : **une vente faite hors ligne n'est jamais rejetée par le serveur**. Elle est enregistrée, et chaque anomalie (prix changé entre-temps, stock insuffisant, lot rappelé) part dans une **file à régulariser** par le pharmacien.

## En bref : ce qui est retenu

Choix techniques validés le 04/10/2026 : Drift chiffré, `pos_sync_offline_sale` séparée, `pos_create_sale` inchangée, code PIN local, horloge interne.

1. Une petite base locale chiffrée sur l'appareil (SQLite avec Drift), réservée au comptoir.
2. Chaque vente reçoit sur l'appareil un identifiant unique ; le serveur s'en sert pour ne jamais enregistrer deux fois la même vente.
3. Une nouvelle fonction serveur, distincte de la vente en ligne, qui accepte toujours la vente et range les anomalies dans une table à part. La vente en ligne (`pos_create_sale`) n'est pas modifiée et reste aussi stricte qu'aujourd'hui.
4. Un écran « À régulariser » pour le pharmacien.
5. Un code PIN local pour continuer à vendre quand la session Supabase a expiré, sans jamais donner accès au serveur.

6. Une ouverture de caisse provisoire hors ligne, avec fond de caisse déclaré, confirmée à la synchronisation.

Effort estimé : **23 à 30 jours de travail**, en huit étapes, ouverture de caisse hors ligne incluse (détail en section 8). Les sept questions sont tranchées (fin de note).

---

## 1. Stockage local

### État actuel du dépôt

- `sqflite` est déjà dans `pubspec.yaml`. Deux services l'utilisent : `OfflineSyncService` (caches en lecture de plusieurs modules, 1 160 lignes de SQL écrit à la main) et `OfflineSalesService` (base de C195).
- Le code de C195 (`OfflineSalesService`, `OfflinePOSProvider`, `OfflinePOSIndicator`) n'est branché nulle part et ne fonctionne pas : identifiant local `offline_…` envoyé dans une colonne uuid, stock serveur non décrémenté, catalogue local jamais rempli (registre, C195).
- PowerSync, prévu au cahier de conception, n'est pas intégré (A35).

### Options comparées

| Option | Avantages | Ce que ça coûte |
|---|---|---|
| **A. SQLite avec Drift** (recommandée) | Tables et requêtes vérifiées à la compilation ; migrations de schéma gérées ; transactions locales ; tests en mémoire sans appareil ; aucun service serveur en plus ; gratuit. | Deux dépendances (`drift`, `drift_dev` avec génération de code) ; il faut écrire nous-mêmes le téléchargement des données et la file d'envoi (étapes 2 et 4). |
| B. `sqflite` écrit à la main (comme aujourd'hui) | Déjà installé, rien à ajouter. | SQL en chaînes de caractères, aucune vérification à la compilation : c'est exactement ce qui a produit les défauts de C195 (colonne `error_message` absente, mauvais type d'identifiant). Peu testable. |
| C. PowerSync, sous-ensemble | Synchronisation des données de lecture (catalogue, stock) automatique et en temps réel ; conforme au cahier de conception. | Un service de plus à faire tourner entre l'appareil et Supabase : offre hébergée (gratuite avec limites, puis abonnement mensuel — tarif à vérifier avant décision) ou auto-hébergement à exploiter nous-mêmes ; réplication logique à activer sur la base ; règles de synchronisation à écrire et à sécuriser par officine. Et surtout : PowerSync ne règle pas notre vrai sujet. L'envoi des ventes passe de toute façon par une fonction que nous écrivons, et la règle « jamais rejetée, anomalies à régulariser » reste entièrement à notre charge. |
| D. Hive, Isar ou fichiers | Simples. | Pas de transactions fiables entre vente, lignes, stock et caisse. Écarté. |

### Recommandation

**Option A, Drift**, dans une base séparée (`comptoir.db`), sans toucher à `OfflineSyncService`.

Pourquoi : le besoin du pilote est étroit. Il faut télécharger un instantané en lecture seule (quelques milliers de lignes) et envoyer une file de ventes. PowerSync apporte beaucoup pour le premier point, rien pour le second, et ajoute un service à surveiller pendant un pilote où nous voulons le moins de pièces mobiles possible. Drift n'empêche pas de passer à PowerSync plus tard (PowerSync s'utilise avec Drift) : le schéma local et les écrans seraient conservés.

Le code de C195 est **remplacé**, pas réparé. `OfflineSyncService` reste en l'état.

### Chiffrement

La base locale est chiffrée (SQLCipher). La clé est créée sur l'appareil et rangée dans le coffre du système (Android Keystore, via `flutter_secure_storage`). Aucune donnée de patient n'est gardée sur l'appareil : une vente hors ligne est anonyme.

---

## 2. Données gardées sur l'appareil

Seules les données de **l'officine du compte connecté** sont téléchargées.

| Donnée | Source serveur | Volume estimé | Mise à jour |
|---|---|---|---|
| Catalogue de l'officine (nom, forme, dosage, code-barres, ordonnance obligatoire ou non) | `products`, limités aux produits présents dans `stock_items` de l'officine | 2 000 à 5 000 produits, environ 1 à 2 Mo | Complète à la connexion et à l'ouverture de caisse ; ensuite toutes les 15 minutes en ligne |
| Prix de vente | `stock_items.unit_price` | Même lignes que le stock | Idem ; chaque prix est gardé avec l'heure serveur à laquelle il a été lu |
| Stock et lots | `stock_items`, `stock_batches` (quantité, réservé, péremption) | 3 000 à 8 000 lots, environ 1 Mo | Idem, et après chaque envoi de ventes réussi |
| Lots rappelés | `recalls` en cours et `recall_affected_batches` | Quelques dizaines à centaines de lignes, moins de 100 Ko | À chaque synchronisation, en premier |
| Session de caisse | `cash_drawer_sessions` (session ouverte du caissier) | 1 ligne | À la connexion, à l'ouverture de caisse, à chaque synchronisation |
| Personnel autorisé sur cet appareil | Résultat de la connexion en ligne (identité, officine, validité) | Quelques lignes | À chaque connexion en ligne |
| File des ventes à envoyer | Créée sur l'appareil | Environ 1,5 Ko par vente ; 300 ventes par jour ≈ 0,5 Mo | Vidée à chaque synchronisation ; ventes envoyées gardées 7 jours pour réimprimer un ticket |

**Total : moins de 10 Mo.** Ces volumes sont des estimations (aucune officine réelle n'est encore en base) ; à mesurer sur la première officine du pilote.

Remarque technique : `stock_batches` n'a pas de colonne `updated_at`. Vu le petit volume, le stock de l'officine est rechargé en entier à chaque mise à jour plutôt que par différences. C'est simple et cela évite une migration.

Le stock local est **décrémenté sur l'appareil** à chaque vente hors ligne, pour que le caissier voie un stock réaliste. Ce n'est qu'un affichage : le stock qui fait foi reste celui du serveur.

---

## 3. Vente hors ligne

### Identifiant unique

À la validation de la vente, l'appareil crée un **uuid v4** (`client_sale_id`). Il est écrit dans la base locale **avant** tout envoi et ne change plus jamais. Le serveur pose une contrainte d'unicité sur (officine, `client_sale_id`) : renvoyer la même vente dix fois donne dix fois la même réponse et une seule vente enregistrée.

Le ticket papier porte un **numéro provisoire** propre à l'appareil (par exemple `HL-A3-0042` : hors ligne, appareil A3, 42ᵉ vente). Le numéro officiel reste attribué par le serveur à la synchronisation (numérotation globale de C197, inchangée) ; le serveur garde le numéro provisoire pour retrouver une vente à partir d'un ticket.

### Déroulement

1. Le caissier compose le panier à partir du catalogue local. Le prix vient du cache, jamais d'une saisie.
2. L'application vérifie localement : caisse ouverte (connue du serveur ou ouverte provisoirement hors ligne), délai de 24 h non dépassé, produit non concerné par un rappel connu, lot non périmé, stock local suffisant, produit non classé stupéfiant ni psychotrope. Médicament sur ordonnance : même avertissement et même confirmation qu'en ligne (D60), sans blocage.
3. Dans **une seule transaction locale** : la vente, ses lignes, la baisse du stock local, l'entrée d'espèces dans la caisse locale, l'ajout à la file.
4. Le ticket provisoire est imprimé ou affiché, avec la mention « Vente enregistrée hors ligne ».

Quand le réseau est là, rien ne change : la vente part directement par `pos_create_sale`, avec ses contrôles stricts. Le chemin hors ligne ne sert que si le réseau est absent au moment de valider.

### File d'attente

Chaque vente de la file a un état : `en attente` → `envoyée` → `acceptée` ou `acceptée avec anomalie`. Il n'existe pas d'état « rejetée ». Une erreur technique (réseau coupé, serveur indisponible) laisse la vente `en attente` et l'envoi est retenté, avec un délai croissant. Les ventes partent dans l'ordre où elles ont été faites.

Un indicateur permanent au comptoir affiche « Hors ligne — N ventes en attente ».

### Ce qui est bloqué hors ligne

| Action | Hors ligne | Raison |
|---|---|---|
| Vente en espèces | Autorisée | Décision du 04/10/2026 |
| Tout autre moyen de paiement | Bloqué | Décision ; pas de confirmation possible |
| Remboursement, retour | Bloqué | Décision ; règle D57 (plafond, jour même, titulaire) non vérifiable sans serveur |
| Remise | Bloquée | Décision 5 |
| Vente d'un stupéfiant ou d'un psychotrope | Bloquée | Décision 7 et complément du 04/10/2026 ; voir « Stupéfiants et psychotropes » ci-dessous |
| Ouverture de caisse | Autorisée, provisoire | Décision 1 ; voir « Ouverture de caisse hors ligne » ci-dessous |
| Fermeture de caisse | Bloquée | Le solde attendu dépend des ventes non envoyées |
| Réception, ajustement, inventaire de stock | Bloqués | Hors périmètre du pilote |
| Vente d'un produit dont le rappel est connu sur l'appareil | Bloquée | Sécurité du patient |
| Vente après 24 h sans synchronisation | Bloquée | Décision |

### Stupéfiants et psychotropes

Le catalogue permet de les identifier : `products.regulatory_class` vaut `libre`, `sur_ordonnance`, `stupefiant` ou `psychotrope` (colonne obligatoire). La classe est téléchargée avec le catalogue ; un produit classé `stupefiant` ou `psychotrope` ne peut pas être ajouté au panier hors ligne, avec le message « Stupéfiant ou psychotrope : vente possible en ligne seulement ».

À savoir :

- La valeur par défaut de la colonne est `libre`. Un stupéfiant ou un psychotrope mal classé au catalogue ne sera pas bloqué. Le contrôle du classement avant le pilote, et une correction pour qu'un oubli de classement ne passe plus inaperçu, sont suivis au registre sous **C241**.
- Les **psychotropes** sont bloqués hors ligne comme les stupéfiants (décision d'Achille, complément du 04/10/2026). En ligne, rien ne change pour eux : avertissement et confirmation de l'ordonnance (D60).

Si une vente de stupéfiant ou de psychotrope arrive tout de même par la synchronisation (application modifiée), le serveur l'enregistre, comme toute vente hors ligne, avec une anomalie de gravité haute.

### Ouverture de caisse hors ligne (décision 1)

Le matin, sans réseau, le caissier peut ouvrir sa caisse :

1. Il déverrouille l'appareil avec son code PIN et déclare son **fond de caisse**.
2. L'appareil crée une **session provisoire** avec son propre identifiant unique, l'heure déclarée et le fond déclaré. Une seule session provisoire par caissier et par appareil ; impossible si l'appareil connaît déjà une caisse ouverte pour ce caissier.
3. Les ventes hors ligne sont rattachées à cette session provisoire. Le ticket et l'écran portent la mention « Caisse ouverte hors ligne, à confirmer ».
4. À la synchronisation, l'ouverture part **avant** les ventes, par une fonction dédiée (`cash_sync_offline_opening`), elle aussi protégée contre les doublons par son identifiant. Trois cas :
   - le caissier n'a aucune caisse ouverte sur le serveur : la session est créée, avec l'origine « hors ligne », l'heure déclarée et l'heure de réception ; l'ouverture est confirmée ;
   - le caissier a déjà une caisse ouverte sur le serveur (ouverte sur un autre appareil, ou non fermée la veille) : aucune seconde session n'est créée (une seule caisse ouverte par caissier) ; les ventes sont rattachées à la session existante et une anomalie « ouverture en double » garde le fond déclaré, à rapprocher ;
   - le caissier n'appartient plus à l'officine : refus d'accès, l'ouverture et ses ventes restent dans la file (décision 3).
5. La **fermeture** reste en ligne seulement, une fois la file vidée.

Le fond déclaré hors ligne n'est vérifié par personne au moment de l'ouverture, comme en ligne. Il apparaît dans le rapport de caisse avec la mention « ouverture hors ligne ».

---

## 4. Synchronisation

### Fonction serveur

Nouvelle fonction `pos_sync_offline_sale`, dans une **nouvelle migration** (aucune migration existante modifiée, `pos_create_sale` intacte). Elle reçoit : l'identifiant unique, l'officine, l'appareil, le vendeur déclaré, l'heure de vente déclarée, l'heure de la dernière synchronisation de l'appareil, les lignes (produit, quantité, prix pratiqué), le total et la session de caisse connue de l'appareil.

Ce qu'elle fait, en **une seule transaction** :

1. Vérifie que l'appelant est du personnel de cette officine (`is_pharmacy_staff`) ou un administrateur GSG. C'est le seul refus possible : c'est un refus d'accès, pas un rejet de vente. La vente reste alors dans la file de l'appareil, jusqu'à ce qu'un autre membre du personnel ou GSG l'envoie (décision 3).
2. Si `client_sale_id` existe déjà : renvoie le résultat déjà enregistré et s'arrête.
3. Enregistre la vente telle qu'elle a eu lieu : quantités et prix **réellement pratiqués**, origine `offline`, heure déclarée par l'appareil et heure de réception par le serveur, appareil, vendeur.
4. Choisit les lots comme en ligne (péremption la plus proche d'abord, verrou sur les lots) et décrémente le stock disponible.
5. Enregistre l'encaissement dans la session de caisse si elle est toujours ouverte.
6. Compare avec l'état du serveur et crée une ligne d'anomalie par écart constaté.
7. Écrit le journal d'audit et renvoie : numéro officiel de la vente et liste des anomalies.

### Anomalies classées

| Anomalie | Quand | Ce que fait le serveur |
|---|---|---|
| Prix changé | Le prix pratiqué diffère du prix actuel du stock | Garde le prix pratiqué ; note l'écart par ligne et au total. Distingue « ancien prix valable à la dernière synchronisation de l'appareil » (normal) de « prix jamais pratiqué par l'officine » (suspect, signalé plus fort). Demande un petit historique des prix (nouvelle table alimentée par déclencheur). |
| Stock insuffisant | Le stock vendable est inférieur à la quantité vendue | Décrémente ce qui est disponible ; enregistre la **quantité manquante** dans l'anomalie. Le stock d'un lot ne devient jamais négatif (voir ci-dessous). |
| Lot rappelé | Un lot attribué à la vente est sous rappel, ou l'a été depuis la dernière synchronisation de l'appareil | Enregistre la vente ; anomalie de gravité haute, en tête de file. |
| Lot périmé | Il ne reste que des lots périmés | Comme stock insuffisant, avec le motif. |
| Caisse fermée entre-temps | La session connue de l'appareil est fermée | Enregistre la vente **sans toucher à la session fermée** (son rapport reste tel que signé) ; l'encaissement est noté « hors session », à rattacher. |
| Produit retiré du stock | Le produit n'est plus au stock de l'officine | Enregistre la ligne sans lot ; anomalie. |
| Compte ou officine désactivés entre-temps | Vendeur détaché de l'officine, ou officine suspendue (C210) | La vente reste dans la file. Un autre membre du personnel l'envoie ; si l'officine est suspendue, GSG l'envoie. Elle est enregistrée avec l'anomalie « vendeur ou officine désactivés » (décision 3). |
| Ouverture en double | Ouverture provisoire hors ligne alors qu'une caisse du même caissier est déjà ouverte sur le serveur | Ventes rattachées à la session existante ; fond déclaré gardé dans l'anomalie. |
| Stupéfiant ou psychotrope vendu hors ligne | Ligne dont le produit est classé `stupefiant` ou `psychotrope` | Enregistre ; anomalie de gravité haute. |
| Heure suspecte | Heure déclarée dans le futur, ou antérieure à la dernière synchronisation | Enregistre ; anomalie d'information. |
| Envoi tardif | Vente faite plus de 24 h après la dernière synchronisation | Enregistre ; anomalie (ne devrait pas arriver, l'appareil bloque avant). |

**Jamais de stock négatif (décision 4).** Deux façons d'enregistrer une vente quand le stock ne suffit pas : laisser la quantité du lot passer sous zéro, ou la garder à zéro et noter le manque à part. La seconde est retenue. Un stock négatif fausserait la recherche de disponibilité des patients, les alertes de seuil et le choix des lots, qui supposent tous une quantité positive. Le manque reste visible et chiffré dans la file à régulariser.

Nouvelle table `pos_sale_anomalies` : vente, ligne, type, détail chiffré, gravité, état (`ouverte`, `régularisée`), décision prise, auteur, date, commentaire. Lecture réservée au personnel de l'officine et à GSG ; **aucune écriture directe** : la régularisation passe par une fonction dédiée, journalisée.

### Écran de régularisation

Nouvel écran « À régulariser » (officine), avec un compteur visible sur le tableau de bord de l'officine et sur l'écran de caisse. Liste triée par gravité, lots rappelés en premier. Pour chaque anomalie : la vente, l'écart chiffré, et les décisions possibles.

| Anomalie | Décisions proposées au pharmacien |
|---|---|
| Prix changé | Accepter l'écart (motif obligatoire). L'écart apparaît dans le rapport de caisse. |
| Stock insuffisant | Corriger le stock après comptage (ajustement par la fonction de stock existante), ou déclarer une réception non saisie. |
| Lot rappelé | « Patient retrouvé et produit récupéré », « Patient non identifiable », avec commentaire obligatoire. Rappel : une vente au comptoir hors ligne est anonyme ; le patient ne pourra souvent pas être retrouvé. |
| Caisse fermée entre-temps | Rattacher l'encaissement à la session suivante comme écart expliqué. |
| Autres | Prendre acte, avec commentaire. |

Chaque régularisation exige un motif et est journalisée avec son auteur.

**Qui régularise (décision 2).** Tout le personnel de l'officine régularise les cas simples. Le **titulaire seul** régularise une anomalie « lot rappelé » et tout écart dont le montant dépasse le plafond de D57 (`pharmacies.pos_refund_staff_limit`, 100 000 GNF par défaut, propre à chaque officine). La règle est appliquée par le serveur, dans la fonction de régularisation ; l'écran grise l'action et affiche « Réservé au titulaire ».

### Deux appareils de la même officine hors ligne en même temps

- **Pas de doublon** : chaque vente a son identifiant, chaque appareil son préfixe de numéro provisoire.
- **Stock vendu deux fois** : les deux appareils partent du même stock connu et peuvent vendre la même dernière boîte. À la synchronisation, le serveur traite les ventes une par une, lots verrouillés : la première reçue prend le stock, la seconde reçoit l'anomalie « stock insuffisant ». L'ordre est celui d'arrivée, pas celui des heures déclarées (non fiables).
- **Caisse** : chaque caissier vend dans sa propre session. En base, la règle est bien « une session ouverte par caissier et par officine » (index `cash_drawer_sessions_one_open` de C205) : deux caissiers peuvent donc vendre en même temps, chacun sur son appareil et dans sa caisse. C'est la règle confirmée (décision 6) ; le texte de D62 au registre a été corrigé.
- **Fermeture de caisse** : le serveur ne peut pas savoir qu'un appareil garde des ventes non envoyées. Proposition : chaque appareil s'enregistre (`pos_devices` : appareil, officine, dernière synchronisation). À la fermeture de caisse, l'écran prévient : « L'appareil A3 n'a pas synchronisé depuis 5 h. »
- **Un appareil partagé par deux employés** : chacun déverrouille avec son code PIN ; la vente porte le vendeur déverrouillé à ce moment-là.

---

## 5. Règle des 24 heures

### Ce qui est mesuré

Le délai court depuis la **dernière synchronisation réussie**. Elle est réussie quand les deux conditions sont réunies : la file de ventes est vide (tout a été reçu par le serveur) **et** les données de référence (prix, stock, rappels, caisse) ont été rechargées. Le serveur renvoie alors son heure ; c'est elle qui est enregistrée, pas celle de l'appareil.

### Comportement

| Délai depuis la dernière synchronisation | Comportement |
|---|---|
| Moins de 12 h | Indicateur discret « Hors ligne — N ventes en attente » |
| De 12 h à 24 h | Bandeau d'avertissement permanent : « Dernière synchronisation il y a 14 h. La vente sera bloquée dans 10 h. Connectez l'appareil. » |
| 24 h et plus | Vente bloquée. La file est conservée, les tickets restent consultables. Une synchronisation réussie débloque immédiatement. |

### Si l'heure de l'appareil est modifiée

L'heure affichée par un téléphone se change en deux gestes ; elle ne peut pas servir seule de mesure.

- **Mesure principale : l'horloge interne du système** (temps écoulé depuis le démarrage de l'appareil). Elle avance toute seule et ne dépend pas du réglage de l'heure. À la synchronisation, l'appareil note sa valeur ; le délai est la différence. Cela demande un petit morceau de code natif Android (quelques lignes).
- **Après un redémarrage**, cette horloge repart de zéro. L'appareil compare alors l'heure affichée à la plus grande heure qu'il a déjà vue (enregistrée à chaque vente et à chaque ouverture). Si l'heure a **reculé**, il retient la plus grande heure connue : le délai ne peut donc jamais diminuer. Un bandeau « Heure de l'appareil incohérente » s'affiche et les ventes suivantes sont marquées « heure suspecte ».
- Si l'heure a été **avancée**, le délai paraît plus long : la vente se bloque plus tôt. C'est gênant, pas dangereux ; une synchronisation règle le problème.
- En cas de doute impossible à lever (redémarrage et heure reculée avant toute vente), l'appareil choisit le cas le plus prudent : vente bloquée jusqu'à la prochaine synchronisation.

Côté serveur, rien n'est rejeté : une vente arrivée avec une heure incohérente ou un délai dépassé est enregistrée avec l'anomalie correspondante.

---

## 6. Connexion hors ligne

### Le problème

Le jeton d'accès Supabase dure 1 heure (`jwt_expiry = 3600`). Son renouvellement demande le réseau. Hors ligne, la session « expire » donc au bout d'une heure, et la connexion par code e-mail est impossible.

### Proposition : un verrou local, distinct de la session serveur

- **Le droit de vendre hors ligne se gagne en ligne.** Il faut s'être connecté par code e-mail sur cet appareil et avoir été reconnu par le serveur comme personnel d'une officine active. L'appareil enregistre alors : qui, quelle officine, jusqu'à quand. La caisse, elle, peut être ouverte hors ligne (section 3).
- **Code PIN à 6 chiffres**, propre à chaque employé et à chaque appareil, choisi en ligne. Il est gardé sous forme d'empreinte lente et salée dans la base chiffrée ; jamais en clair, jamais envoyé au serveur. Sans code PIN défini, pas de vente hors ligne.
- **Verrouillage automatique** après 5 minutes sans activité au comptoir ; le code PIN déverrouille.
- **5 codes faux de suite** : le déverrouillage hors ligne de cet employé est désactivé jusqu'à une connexion en ligne.
- **Durée maximale : 24 h** depuis la dernière synchronisation. C'est la même limite que la règle de vente : au-delà, l'appareil exige le réseau.
- **Le code PIN n'ouvre rien côté serveur.** Il ne remplace pas la session Supabase ; il autorise seulement l'application à écrire dans la file locale. Hors ligne, seuls le comptoir et sa file sont accessibles ; les autres écrans de l'officine demandent le réseau.

### Ce qui se passe à la reconnexion

1. L'application renouvelle la session Supabase avec le jeton de renouvellement gardé sur l'appareil (pas de limite de durée configurée aujourd'hui dans `supabase/config.toml`).
2. Si le renouvellement réussit : synchronisation automatique (ventes, puis données de référence).
3. S'il échoue (compte désactivé, session révoquée) : connexion complète par code e-mail exigée. La file est conservée et part dès qu'un membre du personnel de l'officine est connecté.
4. Le serveur vérifie de nouveau, pour chaque vente, que le vendeur déclaré appartient à l'officine. Sinon : anomalie « vendeur non reconnu ».

### Ce qui reste protégé, et la limite à connaître

- Appareil volé : base chiffrée, code PIN, 5 essais, 24 h au plus, aucune donnée de patient dessus. Le voleur ne peut rien écrire sur le serveur.
- Limite : une vente hors ligne est **déclarée** par l'appareil. Un employé pourrait, en théorie, attribuer une vente à un collègue en modifiant la base locale. Renforcement possible, **hors pilote** : chaque vente signée avec un secret propre à l'employé, remis par le serveur à la connexion en ligne et vérifié à la synchronisation (environ 2 à 3 jours de plus).

---

## 7. Impact sur les règles déjà verrouillées

Principe général : **la vente en ligne ne change pas.** `pos_create_sale` garde tous ses contrôles et ses refus. Le chemin hors ligne est une fonction à part, qui enregistre et signale au lieu de refuser.

| Règle | Aujourd'hui (en ligne) | Ce qui change hors ligne | Ce qui reste garanti |
|---|---|---|---|
| **Prix imposé par le serveur** (C218) | Un prix différent du prix du stock est refusé. | Le serveur ne refuse plus : il enregistre le prix pratiqué et ouvre une anomalie s'il diffère. Le prix pratiqué peut donc avoir jusqu'à 24 h de retard. | Le prix n'est jamais saisi par le caissier : il vient du dernier prix serveur reçu. Tout écart est chiffré, attribué et visible. Un prix qui n'a jamais existé pour l'officine est signalé à part. |
| **Vente sur le vrai stock** (C201, D60) | Lots choisis par le serveur ; stock insuffisant ou lot périmé : vente refusée. | La vente est enregistrée même si le stock ne suffit pas ; le manque part en anomalie. Une vente peut donc exister sans sortie de stock complète. | Le serveur choisit toujours les lots. Plus de catalogue fictif. Aucune quantité de lot négative. Chaque boîte vendue est soit sortie d'un vrai lot, soit inscrite dans la file à régulariser. |
| **Vente et remboursement atomiques** (C197, C203) | Tout ou rien. | Rien ne change : la synchronisation d'une vente est une seule transaction. | Jamais de vente à moitié écrite. Jamais de doublon (identifiant unique). Contrôles de cohérence des montants conservés, mais un écart devient une anomalie au lieu d'un refus. |
| **Numérotation globale** (C197, C202) | Numéro attribué par le serveur. | Le ticket porte d'abord un numéro provisoire ; le numéro officiel arrive à la synchronisation. | Un seul numéro officiel par vente, sans trou ni doublon créé par le hors-ligne. |
| **Remboursement** (C204, D57) | Jour même et plafond hors titulaire, motif, destination du stock. | Remboursement en ligne seulement. Pour une vente hors ligne, le « jour même » se compte depuis **l'heure de vente déclarée par l'appareil** (décision 7), pas depuis l'enregistrement par le serveur. `pos_refund_sale` est donc recréée, dans une nouvelle migration, avec ce seul changement de date de référence. | Toute la règle D57 ; pour une vente en ligne, rien ne change (les tests C204 repassent tels quels). Limite : l'heure déclarée n'est pas prouvée ; elle est bornée par l'heure de réception et par la règle des 24 h. |
| **Caisse liée aux ventes** (C205, D62) | Vente en espèces refusée sans caisse ouverte ; encaissement écrit dans la session. | Vente hors ligne possible avec une caisse ouverte connue de l'appareil, ou ouverte provisoirement hors ligne avec un fond déclaré et confirmée à la synchronisation. Si la caisse a été fermée entre-temps : vente enregistrée, encaissement « hors session » en anomalie. | Une session fermée n'est jamais modifiée. Jamais deux caisses ouvertes pour un même caissier. Tout encaissement en espèces est soit dans une session, soit dans la file à régulariser. |
| **Officine suspendue** (C210) | Plus aucun droit d'écriture. | L'appareil hors ligne ne le sait pas avant de se reconnecter : jusqu'à 24 h de ventes possibles. | Blocage dès la reconnexion. Les ventes déjà faites restent dans la file et sont envoyées par GSG, avec une anomalie (décision 3). |
| **Rôles vérifiés** (C211) | Droits fondés sur le rôle vérifié. | Rien : la fonction de synchronisation vérifie l'appartenance à l'officine. | Personne d'extérieur à l'officine ne peut envoyer une vente. |
| **Journal d'audit** | Écritures seules, auteur et heure serveur. | L'heure de la vente est celle déclarée par l'appareil ; elle n'est pas prouvée. | Le journal garde les deux heures (déclarée et reçue), l'appareil, l'origine `offline`, chaque anomalie et chaque régularisation avec son auteur. Toujours aucune modification ni suppression possible. |

**Prérequis : C240.** `pos_create_sale` ne vérifie aujourd'hui **aucun rappel de lot**, même en ligne. Elle écarte seulement les lots périmés. Le contrôle « lot rappelé » demandé pour le hors-ligne n'a donc pas d'équivalent en ligne. De plus, les rappels désignent les lots par numéro de lot et par produit, pas par lot de stock de l'officine : le rapprochement se fera sur (produit, numéro de lot). Ce point est ouvert au registre sous **C240**, prioritaire ; la fonction de rapprochement écrite pour C240 sera réutilisée telle quelle par `pos_sync_offline_sale`. L'étape 1 du hors-ligne ne commence pas avant la correction et la validation de C240.

---

## 8. Plan de tests et estimation de l'effort

### Tests SQL de la fonction de synchronisation

Nouveau fichier `supabase/sql_tests/c239_pos_offline_sync.sql`, au format des fichiers existants (`CAS n OK` / `CAS n ECHEC`), à lancer après `supabase db reset --local`.

| Cas | Attendu |
|---|---|
| 1. Vente normale | Enregistrée, stock décrémenté, encaissement dans la session, aucune anomalie |
| 2. Même vente envoyée deux fois | Une seule vente, même réponse, stock décrémenté une fois |
| 3. Prix modifié depuis la synchronisation de l'appareil | Enregistrée au prix pratiqué, anomalie « prix changé » avec l'écart |
| 4. Prix jamais pratiqué par l'officine | Enregistrée, anomalie signalée plus fort |
| 5. Stock insuffisant | Enregistrée, stock à zéro (jamais négatif), anomalie avec la quantité manquante |
| 6. Stock nul | Enregistrée, ligne sans lot, anomalie |
| 7. Répartition sur plusieurs lots | Péremption la plus proche d'abord, comme en ligne |
| 8. Lot rappelé avant la vente | Enregistrée, anomalie de gravité haute |
| 9. Lot rappelé entre la vente et l'envoi | Idem |
| 10. Seuls des lots périmés restent | Enregistrée, anomalie |
| 11. Caisse fermée entre-temps | Enregistrée ; session fermée inchangée ; encaissement « hors session » |
| 12. Appelant extérieur à l'officine | Refus d'accès (42501), rien d'écrit |
| 13. Utilisateur anonyme | Refus |
| 14. Vendeur déclaré étranger à l'officine | Enregistrée, anomalie « vendeur non reconnu » |
| 15. Heure déclarée dans le futur | Enregistrée, anomalie « heure suspecte » |
| 16. Vente à plus de 24 h de la dernière synchronisation | Enregistrée, anomalie « envoi tardif » |
| 17. Paiement autre qu'espèces | Refus de la demande (22023) : ce chemin n'accepte que les espèces |
| 18. Montants incohérents | Enregistrée, anomalie |
| 19. Écriture directe dans `pos_sale_anomalies` | Refusée |
| 20. Régularisation | Motif obligatoire, auteur et date enregistrés, journal d'audit écrit ; seconde régularisation refusée |
| 21. Lecture des anomalies par une autre officine | Aucune ligne |
| 22. `pos_create_sale` | Résultats inchangés : les tests C197, C201, C203, C205, C218 et C240 repassent tels quels |
| 23. Régularisation d'un « lot rappelé » par un employé | Refus (42501) ; acceptée pour le titulaire |
| 24. Régularisation d'un écart au-dessus du plafond de l'officine par un employé | Refus (42501) ; acceptée pour le titulaire ; acceptée pour un employé sous le plafond |
| 25. Ouverture de caisse hors ligne, caissier sans caisse ouverte | Session créée avec le fond déclaré, origine « hors ligne », heure déclarée et heure de réception ; mouvement d'ouverture écrit |
| 26. Même ouverture envoyée deux fois | Une seule session, même réponse |
| 27. Ouverture hors ligne alors qu'une caisse du caissier est déjà ouverte | Aucune seconde session ; anomalie « ouverture en double » avec le fond déclaré |
| 28. Ventes rattachées à une ouverture hors ligne | Encaissements dans la session confirmée ; solde attendu = fond déclaré + ventes |
| 29. Ouverture hors ligne avec un fond négatif, ou au nom d'un autre caissier | Refus de la demande (22023, 42501) |
| 30. Vente d'un stupéfiant, puis d'un psychotrope | Enregistrées, anomalie de gravité haute pour chacune |
| 31. Remise non nulle | Refus de la demande (22023) : ce chemin n'accepte aucune remise |
| 32. Envoi par GSG pour une officine suspendue | Vente enregistrée, anomalie « vendeur ou officine désactivés » ; même envoi par un compte ordinaire : refus |
| 33. Remboursement d'une vente hors ligne (`pos_refund_sale`) | « Jour même » compté depuis l'heure déclarée : employé accepté le jour de la vente déclarée, refusé le lendemain même si le serveur a reçu la vente ce jour-là ; tests C204 inchangés pour une vente en ligne |

Script de concurrence (sur le modèle de `concurrency_numbering.sh`) : deux sessions envoient en même temps deux ventes de la dernière boîte. Attendu : deux ventes enregistrées, une seule anomalie « stock insuffisant », stock à zéro. Et : la même vente envoyée par deux sessions en même temps donne une seule vente.

### Tests Flutter

- **Base locale** (Drift en mémoire) : vente locale en une transaction ; stock local décrémenté ; file dans l'ordre ; reprise après arrêt brutal de l'application au milieu d'un envoi.
- **Règle des 24 h** (horloge simulée) : indicateur avant 12 h, bandeau à 12 h, blocage à 24 h, déblocage après synchronisation, heure reculée, heure avancée, redémarrage.
- **Code PIN** : bon code, 5 erreurs, verrouillage après inactivité, expiration à 24 h.
- **Ouverture de caisse hors ligne** : fond déclaré, une seule session provisoire par caissier, ouverture envoyée avant les ventes, cas « ouverture en double ».
- **Blocages** : stupéfiant et psychotrope refusés au panier hors ligne, remise indisponible, fermeture de caisse indisponible.
- **Écrans** : comptoir hors ligne (moyens autres qu'espèces absents, remboursement inaccessible), ouverture de caisse hors ligne, écran « À régulariser » (action réservée au titulaire grisée pour un employé), à 360 px.

### Tests sur appareil réel

Sur un téléphone Android, en mode avion : ouverture de caisse le matin sans réseau ; une journée de ventes simulée ; coupure du réseau au milieu d'un envoi ; redémarrage hors ligne ; changement de l'heure ; deux appareils sur la même officine ; reconnexion après expiration de la session. Ces tests ne peuvent pas être remplacés par des tests automatiques.

### Estimation par étape

Estimations en jours de travail, à affiner après validation de la note. Elles ne reposent sur aucune mesure : c'est un ordre de grandeur.

| Étape | Contenu | Effort |
|---|---|---|
| Préalable | C240 : lot rappelé refusé en ligne (hors de ce total, estimé à 1,5 à 2 j) | — |
| 0 | Décisions d'Achille sur les sept questions | fait le 04/10/2026 |
| 1 | Serveur : migration (identifiant unique, origine, heures, appareils, anomalies, historique des prix), `pos_sync_offline_sale`, `cash_sync_offline_opening`, fonction de régularisation avec la règle du titulaire, envoi par GSG, `pos_refund_sale` sur l'heure déclarée, tests SQL et concurrence | 5 à 6 j |
| 2 | Base locale Drift chiffrée, téléchargement de l'instantané de l'officine | 3 à 4 j |
| 3 | Comptoir hors ligne : panier sur les données locales, vente locale, ticket provisoire, blocages (stupéfiants, psychotropes, remises), ouverture de caisse provisoire | 4 à 5 j |
| 4 | Moteur de synchronisation : file (ouverture puis ventes), reprises, indicateur | 2 à 3 j |
| 5 | Règle des 24 h, bandeau, horloge interne (code natif Android) | 1,5 à 2 j |
| 6 | Verrou local et code PIN | 2 à 3 j |
| 7 | Écran « À régulariser » et compteurs | 2 à 3 j |
| 8 | Tests sur appareil réel, corrections, mise à jour du registre | 3 à 4 j |
| | **Total** | **23 à 30 j** |

Par rapport à la première version (21 à 28 j) : + 2 jours pour l'ouverture de caisse hors ligne, répartis sur les étapes 1 et 3. Les autres décisions (titulaire pour certaines régularisations, envoi par GSG, stupéfiants, heure déclarée pour le remboursement) tiennent dans les fourchettes des étapes 1 et 3.

Ordre conseillé : C240 d'abord ; puis l'étape 1, seule. Elle se teste entièrement en SQL, sans application, et c'est elle qui porte les garanties. Chaque étape fait l'objet d'un commit et d'une relecture avant la suivante.

---

## Questions : décisions d'Achille (04/10/2026)

| # | Question | Décision |
|---|---|---|
| 1 | Ouverture de caisse hors ligne | **Permise.** Ouverture provisoire avec fond de caisse déclaré, confirmée à la synchronisation (section 3, « Ouverture de caisse hors ligne » ; tests 25 à 29). |
| 2 | Qui régularise ? | **Tout le personnel** pour les cas simples ; **titulaire seul** pour « lot rappelé » et pour un écart au-dessus du plafond de D57 (section 4). |
| 3 | Compte ou officine désactivés pendant le hors-ligne | Les ventes restent dans la file ; un autre membre du personnel, ou GSG, les envoie ; elles sont enregistrées avec une anomalie. Chemin d'envoi par GSG pour une officine suspendue (section 4). |
| 4 | Stock insuffisant | Manque noté à part, **jamais de stock négatif**. |
| 5 | Remises hors ligne | **Bloquées.** |
| 6 | Caisses | **Une session ouverte par caissier**, comme la base. Texte de D62 corrigé au registre. |
| 7 | Ordonnance, stupéfiants, remboursement | Ordonnance : avertissement comme en ligne (D60). Stupéfiants et psychotropes (complément du 04/10/2026) : vente **bloquée** hors ligne ; le catalogue permet de les identifier (`products.regulatory_class`), sous réserve qu'ils soient bien classés (section 3, « Stupéfiants »). Remboursement « jour même » (D57) : compté depuis **l'heure de vente déclarée par l'appareil** ; la recréation de `pos_refund_sale` est acceptée, dans l'étape 1. |

Plus aucune question ouverte. Le contrôle du classement réglementaire du catalogue est suivi sous C241.

# PharmaConnect — Parcours réel de la réservation (C243, lot 3)

**Pour qui :** Achille, qui joue le parcours lui-même avec deux téléphones Android et trois comptes.
**État :** guide préparé le 04/10/2026. Rien n'a été exécuté en production pour ce guide.
**Durée :** environ 1 h 30 le premier jour, 10 minutes le lendemain (réservation expirée).

---

## 0. À lire avant tout : le parcours n'est pas jouable aujourd'hui

En préparant ce guide, j'ai relu le code de chaque écran du parcours. **Trois manques bloquent le parcours sur un téléphone.** Les fonctions du serveur existent et sont testées ; ce sont les chemins dans l'application qui manquent.

| # | Manque | Conséquence | Registre |
|---|---|---|---|
| 1 | Sur la fiche d'un produit, le bouton « Réserver ce produit » ne fait rien. Rien dans l'application n'ajoute un produit au panier de réservation, et aucun lien ne mène au panier. | **Un patient ne peut pas réserver.** | C245 |
| 2 | Aucun menu ni bouton ne mène à l'administration (`/admin`), à la caisse (`/cash`) ni à la file des réservations de l'officine (`/pharmacy/queue`). Sur un téléphone, on ne peut pas saisir une adresse. | **L'administrateur ne peut pas valider l'officine ; le pharmacien ne peut ni ouvrir sa caisse, ni voir la file, ni faire un retrait.** | C245 |
| 3 | Aucun écran ne crée le premier stock d'une officine : ni l'article, ni le lot, ni le prix de vente. L'écran « Réception » de la traçabilité écrit dans une autre table et n'alimente pas le stock vendable. | **L'officine de test n'aura rien à vendre ni à réserver.** | C246 |

**Ce que je propose** (détail à la fin, section 11) :

- manques 1 et 2 : une correction de l'application avant de jouer le parcours (C245) ; il n'existe pas d'autre moyen ;
- manque 3 : pour ce parcours, une requête de mise en stock exécutée par Achille (section 4) ; pour le pilote, un vrai écran de réception (C246).

**Les étapes ci-dessous décrivent le parcours tel qu'il se jouera une fois C245 livré.** Les noms exacts des nouveaux boutons seront ajustés dans ce guide à ce moment-là ; ils sont marqués « (après C245) ».

---

## Matériel et comptes

| Élément | Rôle dans le parcours |
|---|---|
| Téléphone A | l'officine : compte administrateur d'abord, puis compte pharmacien |
| Téléphone B | le patient |
| Adresse « admin » | `votre.adresse+admin@gmail.com` |
| Adresse « pharmacien » | `votre.adresse+pharmacien@gmail.com` |
| Adresse « patient » | `votre.adresse+patient@gmail.com` |

Les trois adresses arrivent dans la même boîte Gmail. Chaque connexion envoie un **code par e-mail** : c'est le code du **dernier** e-mail reçu qui compte, un code plus ancien est refusé.

**À noter en cas d'écart, à chaque étape :** une capture d'écran, l'heure (heure et minute), le téléphone (A ou B) et le compte utilisé. Ne pas insister ni réessayer plusieurs fois : noter, puis me le signaler avant de continuer.

**Entre deux étapes**, je fais un contrôle en production, **en lecture seule** (je lis, je n'écris rien). Attendez mon « conforme » avant de passer à l'étape suivante.

---

## 1. Installation

**L'application installée parle directement à la production** : l'adresse de la base est écrite dans l'application, il n'existe pas de version « d'essai ». Tout ce que vous faites est réel.

1. Je construis le fichier d'installation (APK) à partir de `main`, après C245, et je vous donne son nom et le numéro du commit. Le fichier est signé avec une clé d'essai : il s'installe à la main, il ne vient pas du Play Store.
2. Copiez le fichier sur chaque téléphone (câble USB, ou Google Drive puis « Télécharger »).
3. Sur le téléphone, ouvrez le fichier. Android demande d'autoriser l'installation depuis cette source : acceptez, puis « Installer ».
4. Si Play Protect affiche un avertissement : « Installer quand même ».

**Vous devez voir :** l'icône PharmaConnect, puis l'écran « Connexion » avec un seul champ, l'adresse e-mail.

**Se déconnecter et changer de compte :** bouton ☰ en haut à droite, puis « Se déconnecter » en bas du menu, puis confirmer. L'écran « Connexion » revient ; saisissez l'autre adresse.

**Contrôle de ma part :** aucun à cette étape.

---

## 2. Premier administrateur GSG (la seule écriture à la main)

Aucun compte ne peut se nommer administrateur lui-même : c'est voulu. Le premier administrateur est donc inscrit une fois, à la main, dans l'éditeur SQL de Supabase.

### 2.1 Créer le compte « admin » (téléphone A)

1. Écran « Connexion » → « S'inscrire ».
2. Nom complet : `Administrateur GSG`. « Je suis un(e) : » **Patient** (le rôle d'administrateur ne se choisit pas à l'inscription). Adresse : l'adresse « admin ».
3. Saisissez le code reçu par e-mail.

**Vous devez voir :** le tableau de bord d'un patient. Si l'application demande de compléter le profil, remplissez-le.

**Contrôle de ma part :** le compte existe, son adresse est confirmée, et la table des administrateurs est vide.

### 2.2 La requête, à exécuter par Achille

Dans Supabase : projet PharmaConnect → « SQL Editor » → nouvelle requête. Collez ceci **après avoir remplacé l'adresse à la ligne 3** par votre adresse « admin » exacte, puis « Run ».

```sql
do $$
declare
  v_email constant text := 'votre.adresse+admin@gmail.com';  -- la seule ligne à modifier
  v_user_id uuid;
  v_confirmed timestamptz;
  v_count integer;
begin
  if v_email not like '%+admin@gmail.com' then
    raise exception 'ARRET : % n''est pas l''adresse attendue (elle doit finir par +admin@gmail.com). Rien n''est ecrit.', v_email;
  end if;

  if exists (select 1 from public.admin_users) then
    raise exception 'ARRET : un administrateur existe deja. Rien n''est ecrit.';
  end if;

  select count(*) into v_count from auth.users where lower(email) = lower(v_email);
  if v_count <> 1 then
    raise exception 'ARRET : % compte(s) trouve(s) pour %, un seul attendu. Rien n''est ecrit.', v_count, v_email;
  end if;

  select id, email_confirmed_at into v_user_id, v_confirmed
    from auth.users where lower(email) = lower(v_email);
  if v_confirmed is null then
    raise exception 'ARRET : l''adresse % n''a pas ete confirmee par un code. Rien n''est ecrit.', v_email;
  end if;

  insert into public.admin_users (user_id, email, full_name, role, is_active, is_verified, notes)
  values (v_user_id, lower(v_email), 'Administrateur GSG', 'superAdmin', true, true,
          'Premier administrateur GSG, inscrit a la main le 04/10/2026 (C243, lot 3).');

  raise notice 'OK : % est administrateur GSG.', v_email;
end;
$$;
```

Ce que fait la requête : elle ajoute **une seule ligne**, dans la table des administrateurs. Elle s'arrête sans rien écrire si l'adresse ne finit pas par `+admin@gmail.com`, si le compte n'existe pas ou n'est pas confirmé, ou si un administrateur existe déjà.

**Vous devez voir :** « Success. No rows returned ». Un message commençant par « ARRET » veut dire que rien n'a été écrit : envoyez-moi le message.

### 2.3 La requête de vérification (lecture seule)

```sql
select a.email, a.role, a.is_active, (u.email = a.email) as meme_compte, a.created_at
from public.admin_users a
join auth.users u on u.id = a.user_id;
```

**Vous devez voir :** exactement une ligne, avec votre adresse « admin », `superAdmin`, `true`, `true`.

### 2.4 Dans l'application

Déconnectez-vous puis reconnectez-vous avec le compte « admin » (le droit est lu à la connexion).

**Vous devez voir (après C245) :** une entrée « Administration » dans le menu ☰.

**Contrôle de ma part :** une seule ligne d'administrateur, liée au bon compte.

---

## 3. Pharmacien et officine de test

### 3.1 Inscription du pharmacien (téléphone A, après déconnexion du compte admin)

1. « S'inscrire ». Nom complet : `TEST Pharmacien`. « Je suis un(e) : » **Pharmacien titulaire**. Adresse « pharmacien ».
2. Code reçu par e-mail.

**Vous devez voir :** l'écran « Vérification de licence ».

### 3.2 Candidature de l'officine

Remplissez :

| Champ | Valeur |
|---|---|
| Nom de l'officine | `TEST Officine Lot 3` |
| Numéro de licence | `TEST-LIC-0001` |
| Nom du titulaire | `TEST Pharmacien` |
| Adresse de l'officine | `TEST — adresse fictive, Conakry` |

Puis « Soumettre la vérification ».

**Vous devez voir :** le tableau de bord, avec un bandeau qui dit que la candidature de « TEST Officine Lot 3 » est en attente, et que vous utilisez l'application comme un patient en attendant. Le menu « Stock & Lots » n'apparaît pas encore.

**Contrôle de ma part :** une officine « TEST Officine Lot 3 » à l'état « en attente », titulaire = le compte pharmacien ; le compte n'est encore rattaché à aucune officine.

### 3.3 Validation par l'administrateur (téléphone A)

1. Déconnectez le pharmacien, connectez le compte « admin ».
2. Menu ☰ → « Administration » (après C245) → « Officines » → filtre « en attente ».
3. Sur « TEST Officine Lot 3 » : « Vérifier la licence », puis « Approuver ».

**Vous devez voir :** l'officine passe à l'état « active ».

**Je ne suis pas sûr de cette étape :** ces deux boutons n'ont jamais été utilisés avec un vrai compte administrateur en production. En cas de message d'erreur, capture et heure.

**Contrôle de ma part :** officine à l'état « active » ; le compte pharmacien est rattaché à cette officine (c'est le serveur qui le fait, à la validation).

### 3.4 Accès débloqué (téléphone A)

Déconnectez l'admin, reconnectez le pharmacien.

**Vous devez voir :** plus de bandeau d'attente ; le menu « Stock & Lots » ; sur le tableau de bord, les actions « Caisse » et « Personnel » ; et (après C245) « File des réservations » et « Ouverture de caisse » dans le menu.

---

## 4. Premier stock de l'officine de test

**Ce chemin n'existe pas dans l'application** (manque 3). L'écran « Stock & Lots » sait ajuster un lot qui existe déjà, pas en créer un premier ; il ne permet pas de fixer un prix de vente.

**Alternative proposée, soumise à votre accord :** une requête exécutée par Achille dans l'éditeur SQL, sur le modèle de celle de l'administrateur. Elle met en stock deux produits sans ordonnance dans la seule officine dont le nom commence par « TEST », et s'arrête sans rien écrire dans tous les autres cas.

```sql
do $$
declare
  v_pharmacy_id uuid;
  v_count integer;
  v_item_id uuid;
  v_line record;
begin
  select count(*) into v_count from public.pharmacies where name like 'TEST %' and status = 'active';
  if v_count <> 1 then
    raise exception 'ARRET : % officine(s) active(s) dont le nom commence par TEST, une seule attendue. Rien n''est ecrit.', v_count;
  end if;
  select id into v_pharmacy_id from public.pharmacies where name like 'TEST %' and status = 'active';

  if exists (select 1 from public.stock_items where pharmacy_id = v_pharmacy_id) then
    raise exception 'ARRET : l''officine de test a deja du stock. Rien n''est ecrit.';
  end if;

  for v_line in
    select * from (values
      ('33333333-3333-3333-3333-333333330001'::uuid, 1500, 'TEST-LOT3-A'),
      ('33333333-3333-3333-3333-333333330004'::uuid, 1200, 'TEST-LOT3-B')
    ) as t(product_id, unit_price, batch_number)
  loop
    if not exists (
      select 1 from public.products p
      where p.id = v_line.product_id and not p.is_prescription_required
        and p.regulatory_class = 'libre'
    ) then
      raise exception 'ARRET : produit % absent du catalogue ou soumis a ordonnance. Rien n''est ecrit.', v_line.product_id;
    end if;

    insert into public.stock_items (pharmacy_id, product_id, total_quantity, reserved_quantity, unit_price, status)
    values (v_pharmacy_id, v_line.product_id, 10, 0, v_line.unit_price, 'inStock')
    returning id into v_item_id;

    insert into public.stock_batches (stock_item_id, batch_number, manufacturing_date, expiry_date,
                                      quantity, quantity_reserved, received_at, supplier_name)
    values (v_item_id, v_line.batch_number, current_date - 30, current_date + 365,
            10, 0, now(), 'TEST fournisseur');
  end loop;

  raise notice 'OK : 2 articles et 2 lots de 10 boites dans l''officine de test.';
end;
$$;
```

Ce que fait la requête : 2 lignes d'articles et 2 lignes de lots (10 boîtes chacun), rien d'autre. Les deux produits sont ceux du catalogue de démonstration (Paracétamol et Aspirine) ; **je vérifierai en lecture seule, avant de vous la confier, que ces deux identifiants existent bien en production et sont sans ordonnance**, et j'ajusterai la requête sinon.

**Vous devez voir (téléphone A, compte pharmacien) :** menu « Stock & Lots » → deux articles, 10 boîtes chacun, 0 réservée.

**Contrôle de ma part :** 2 articles et 2 lots pour l'officine de test, 20 boîtes, aucune quantité réservée ; rien de changé dans les autres officines.

---

## 5. Ouverture de la caisse (téléphone A, pharmacien)

Sans caisse ouverte, le serveur refuse tout retrait (« ouvrez votre caisse »).

1. Menu ☰ → « Ouverture de caisse » (après C245).
2. **Vous devez voir :** « Aucune caisse ouverte — Ouvrez une session pour commencer ».
3. « Ouvrir la caisse » → fond de caisse : `0` → « Ouvrir ».

**Vous devez voir :** « Caisse ouverte avec succès », puis un résumé de la session.

**Je ne suis pas sûr de cette étape :** l'écran n'a pas été joué avec un vrai compte.

**Contrôle de ma part :** une session de caisse ouverte, pour ce pharmacien et cette officine.

---

## 6. Patient : inscription et réservation (téléphone B)

### 6.1 Inscription

« S'inscrire ». Nom complet : `TEST Patient`. « Je suis un(e) : » **Patient**. Adresse « patient ». Code reçu par e-mail.

Un compte patient existe déjà en production. Si l'adresse « patient » est déjà la sienne, utilisez « Se connecter » au lieu de « S'inscrire ».

### 6.2 Recherche

Menu ☰ → « Recherche » → saisir `Paracétamol` → ouvrir la fiche du produit.

**Vous devez voir :** la liste des officines qui ont le produit, dont « TEST Officine Lot 3 » avec 10 boîtes. Les officines de démonstration apparaissent aussi : **ne réservez que dans l'officine TEST.**

### 6.3 Réservation n° 1 (elle servira au retrait par scan)

1. Sur la ligne « TEST Officine Lot 3 » : « Réserver » (après C245), quantité `2`.
2. Panier → « Passer la commande ».
3. Récapitulatif : **vous devez voir** « Prix indicatif, le prix du jour s'applique au retrait », le total 3 000 GNF, et le paiement au retrait à l'officine. Aucune étape « Livraison » ni « Créneau ».
4. « Confirmer la commande ».

**Vous devez voir :** l'écran de confirmation, avec un QR, **un code de 6 caractères** sous le QR (sans 0, O, 1 ni I), et l'échéance de retrait (24 h plus tard).

**Notez le code n° 1.**

### 6.4 Réservation n° 2 (retrait par saisie du code)

Même chose avec `Aspirine`, quantité `1`. **Notez le code n° 2.** Les deux codes doivent être différents.

### 6.5 Retrouver le QR et le code

Menu ☰ → « Réservations ». **Vous devez voir** les deux réservations à l'état « Réservée », chacune avec son échéance. Ouvrir une réservation réaffiche le QR et le code.

**Contrôle de ma part :** deux réservations à l'état « réservée », au nom du compte patient, dans l'officine de test ; 2 boîtes de Paracétamol et 1 d'Aspirine retenues ; échéance à 24 h ; deux codes différents de 6 caractères. Disponible affiché aux patients : 8 et 9.

---

## 7. Officine : file, « Prête », retrait (téléphone A, pharmacien)

### 7.1 La file

Menu ☰ → « File des réservations » (après C245).

**Vous devez voir :** les deux réservations de « TEST Patient », avec les boutons « Prête », « Retrait » et « Annuler ». Le code de retrait n'est **pas** affiché à l'officine.

Dans « Stock & Lots » : Paracétamol, 10 boîtes dont 2 réservées ; Aspirine, 10 dont 1 réservée.

### 7.2 « Prête »

Sur la réservation n° 1 : « Prête ».

**Vous devez voir :** l'état passe à « prête ». Sur le téléphone B (menu « Réservations », tirer pour rafraîchir) : la réservation n° 1 est « prête ». L'échéance n'a pas bougé.

### 7.3 Retrait n° 1, par scan du QR

1. Téléphone B : afficher le QR de la réservation n° 1.
2. Téléphone A : « Retrait » sur la réservation n° 1.
3. **Vous devez voir :** la barre du haut « Retrait », le nom du patient, le champ « Code de retrait du patient », la liste des produits, « À encaisser en espèces : 3 000 GNF ». Le bouton « Encaisser et remettre » est grisé tant que le code est vide.
4. Touchez l'icône de QR dans le champ du code. Android demande l'accès à l'appareil photo : acceptez. Visez le QR du téléphone B.
5. **Vous devez voir :** le code se remplit tout seul, identique au code n° 1.
6. « Encaisser et remettre ».

**Vous devez voir :** « Retrait enregistré : vente créée », puis le ticket de la vente (3 000 GNF, espèces).

**Je ne suis pas sûr de cette étape :** le scan du QR n'a jamais été essayé sur un vrai téléphone. Si le scan ne marche pas, notez-le (capture, heure) et saisissez le code à la main pour continuer.

### 7.4 Retrait n° 2, par saisie du code

« Retrait » sur la réservation n° 2 (sans passer par « Prête » : c'est permis). Saisissez le code n° 2 au clavier, en minuscules si vous voulez : il est accepté. « Encaisser et remettre ».

**Vous devez voir :** le ticket, 1 200 GNF.

### 7.5 Après les deux retraits

- Téléphone A, « Stock & Lots » : Paracétamol 8 boîtes, 0 réservée ; Aspirine 9 boîtes, 0 réservée.
- Téléphone A, caisse : deux encaissements, 4 200 GNF au total.
- Téléphone B, « Réservations » → « Terminées » : les deux réservations sont « retirées ».

**Contrôle de ma part :** deux ventes en espèces (3 000 et 1 200), deux tickets, deux encaissements sur la session de caisse, chacune reliée à sa réservation ; stock sorti une seule fois (8 et 9) ; plus aucune boîte retenue.

---

## 8. Cas d'erreur à jouer

Pour chaque cas, le patient crée d'abord une nouvelle réservation de 1 boîte de Paracétamol dans l'officine TEST (comme en 6.3).

### 8.1 Code faux

Téléphone A : « Retrait », saisir `ABCDEF`, « Encaisser et remettre ».

**Vous devez voir :** un message rouge « Code de retrait incorrect ». Aucun ticket. La réservation reste dans la file.

Essayez aussi avec le **code n° 1** (déjà utilisé) : même refus.

**Contrôle de ma part :** aucune vente créée, la boîte toujours retenue.

### 8.2 Annulation par le patient

Téléphone B : « Réservations » → cette réservation → « Annuler » → confirmer.

**Vous devez voir :** la réservation passe dans « Terminées », état « annulée ». Téléphone A : elle disparaît de la file ; le stock revient à 0 réservée.

**Contrôle de ma part :** réservation annulée par le patient, boîte libérée.

### 8.3 Annulation par l'officine, avec motif

Nouvelle réservation côté patient. Téléphone A : « Annuler » → sans motif, **vous devez voir** que la validation est refusée. Saisissez `TEST produit abîmé` → « Annuler la réservation ».

**Vous devez voir :** téléphone B, la réservation « annulée », avec le motif.

**Contrôle de ma part :** réservation annulée par le pharmacien, motif enregistré, boîte libérée.

### 8.4 Réservation laissée expirer

Nouvelle réservation côté patient. **Notez l'heure exacte.** Ne faites rien d'autre.

**Le lendemain, plus de 24 h après :**

- Téléphone B, « Réservations » → « Terminées » : la réservation est « expirée ».
- Téléphone A, file : elle n'y est plus. « Stock & Lots » : 0 réservée.
- Téléphone A (facultatif) : il n'y a plus de bouton « Retrait » pour cette réservation.

**Contrôle de ma part, le lendemain :** réservation à l'état « expirée », heure d'expiration dans le quart d'heure qui suit l'échéance (la tâche planifiée passe toutes les 15 minutes), boîte libérée ; le journal de la tâche planifiée ne montre aucun échec.

### 8.5 Fin de journée

Téléphone A : caisse → « Fermer la caisse », avec le montant compté (4 200).

---

## 9. Récapitulatif des contrôles en lecture seule

| Après l'étape | Ce que je lis en production |
|---|---|
| 2.1 | compte admin créé et confirmé ; aucun administrateur |
| 2.3 | un seul administrateur, lié au bon compte |
| 3.2 | officine TEST en attente, titulaire correct, pharmacien non rattaché |
| 3.3 | officine active, pharmacien rattaché |
| 4 | 2 articles, 2 lots, 20 boîtes, 0 réservée ; autres officines inchangées |
| 5 | une session de caisse ouverte |
| 6 | 2 réservations, 3 boîtes retenues, 2 codes différents |
| 7 | 2 ventes, 2 tickets, 2 encaissements, stock 8 et 9, 0 retenue |
| 8.1 | aucune vente, boîte retenue |
| 8.2 et 8.3 | annulations, auteur et motif, boîtes libérées |
| 8.4 (lendemain) | expiration par la tâche planifiée, boîte libérée |

Tous ces contrôles sont des lectures. Aucune écriture de ma part en production pendant le parcours.

---

## 10. Données de test qui resteront en production

| Donnée | Comment la reconnaître |
|---|---|
| 3 comptes (admin, pharmacien, patient) | adresses en `+admin`, `+pharmacien`, `+patient` ; noms « TEST Pharmacien », « TEST Patient » |
| 1 ligne d'administrateur | **à garder** : c'est le vrai premier administrateur GSG, pas une donnée de test |
| 1 officine | nom « TEST Officine Lot 3 », licence « TEST-LIC-0001 » |
| 2 articles et 2 lots | lots « TEST-LOT3-A » et « TEST-LOT3-B », fournisseur « TEST fournisseur » |
| 1 session de caisse et ses mouvements | caissier « TEST Pharmacien » |
| 5 à 6 réservations et leurs lignes | officine TEST |
| 2 ventes, 2 tickets, leurs lignes | officine TEST ; elles consomment 2 numéros de ticket de la numérotation globale |
| mouvements de stock, journal d'audit | rattachés à l'officine TEST |

**Tant que l'officine TEST est active, les patients la voient dans la recherche.** Aujourd'hui il n'y a pas d'autre patient ; avant le pilote, il faudra la retirer de la vue.

**Retrait, plus tard, en deux temps, chacun soumis à votre accord :**

1. **Tout de suite après le parcours, sans rien supprimer :** l'administrateur « suspend » l'officine TEST depuis l'application (bouton « Suspendre »). Elle n'apparaît plus aux patients et ne peut plus vendre. Les données restent, pour relecture.
2. **Avant le pilote :** une migration de nettoyage, testée en local d'abord, qui supprime dans l'ordre tout ce qui est rattaché à l'officine dont le nom commence par « TEST » et aux deux comptes « TEST », avec un garde-fou (elle s'arrête si elle trouve autre chose que ce qui est listé ci-dessus). Les ventes et les tickets portent des numéros officiels : je vous proposerai de les **garder, marqués comme essais**, plutôt que de créer un trou dans la numérotation. La ligne d'administrateur est conservée.

---

## 11. Ce qu'il faut décider avant de jouer le parcours

1. **C245 — rendre le parcours atteignable dans l'application** (obligatoire) :
   - fiche produit : « Réserver » sur une officine ajoute le produit au panier de réservation pour cette officine et ouvre le panier ;
   - menu du pharmacien vérifié : « File des réservations » et « Ouverture de caisse » ;
   - menu de l'administrateur GSG : « Administration ».
   Aucun changement côté serveur. Captures à 360 px, puis construction de l'APK.
2. **Mise en stock de l'officine TEST par requête** (section 4), pour ce parcours.
3. **C246 — réception de stock dans l'application** (création d'un article, d'un lot et du prix de vente par le personnel, par une fonction du serveur) : nécessaire avant le pilote, pas avant ce parcours.
4. **La requête du premier administrateur** (section 2.2), à exécuter par Achille.

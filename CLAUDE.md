# CLAUDE.md — Portefeuille GSG (Global Service Groupe)

Ce fichier donne à Claude le contexte architectural du portefeuille GSG avant toute intervention sur un dépôt de code. Il résume trois documents de référence : le **GSG Platform Kernel v3.0**, le **Modèle d'authentification Supabase**, et le cahier de conception **PharmaConnect v2.1**. Il n'y a pas encore de dépôt de code associé à ces cahiers — ce fichier sert de socle à copier/adapter dans chaque futur dépôt produit.

## Vue d'ensemble

GSG développe un portefeuille de produits indépendants (PharmaConnect, Ecclesias 360, EduRéussite, GlobalStock ERP, AssoShop, TradeLink Africa, SecureGuard, EcoShop...) qui partagent un socle d'infrastructure commun : le **GSG Platform Kernel**. Chaque produit garde sa propre base de données et son autonomie technique complète ; seuls l'identité, les métadonnées d'organisation, le référentiel partagé, les événements et l'audit traversent les frontières entre produits.

Principe cardinal (KER-VIS-04) : un produit qui n'intègre aucune brique du noyau doit rester pleinement fonctionnel de façon autonome. L'intégration au noyau est toujours une option, jamais une dépendance obligatoire.

## Le GSG Platform Kernel

Le Kernel n'est pas un produit vendu au client final : c'est une couche d'infrastructure interne partagée, dont l'unique raison d'être est d'éviter que chaque produit ne réimplémente séparément l'authentification, la gestion des organisations, le référentiel pays/devise/langue, la modélisation des variations structurelles inter-pays, l'audit et les autres mécanismes transverses.

### Briques du noyau

| Brique | Rôle |
|---|---|
| **GSG ID** | Fournisseur d'identité central (OIDC/OAuth2), authentification unique inter-produits, MFA implémenté une seule fois. Profil utilisateur portant `pays_id`, `unite_administrative_id`, `ville_id`, `langue_id`, `devise_id`, `fuseau_horaire`. Téléphones stockés au format E.164. |
| **Org Registry** | Registre central des organisations clientes, identifiant global `gsg_org_id`. |
| **Registre des produits** | Catalogue central des produits du portefeuille. |
| **GSG Referential** | Référentiel unique pays/devise/langue/bloc régional, unités administratives et villes — nommage en français (`pays`, `devise`, `langue`, `bloc_regional`, `ville`, `taux_change`). |
| **GSG Referential Engine** | Méta-modèle générique (`referentiel_hierarchique`, `referentiel_regle`, `corpus_versionne`, `corpus_element`) capable de modéliser n'importe quelle variation structurelle entre pays, dans n'importe quel domaine métier, via un `code_domaine` propre à chaque produit. |
| **AppConfig** | Consommation côté client des paramètres hérités du référentiel. |
| **Bus d'événements** | Diffusion d'événements inter-produits ; aucune donnée sensible (santé, financière, scolaire nominative) sans finalité explicite et base légale documentée. |
| **Audit** | Journalisation centralisée infalsifiable, notamment pour les accès aux données sensibles. |
| **Billing Core** | Facturation unifiée — **différée par défaut**, activée uniquement sur décision commerciale explicite (KER-BIL-02). |
| **Design System** | Bibliothèque de composants Flutter partagée — **non urgente**, adoption progressive et non bloquante (KER-DES-02). Composants bâtis sur des tokens sémantiques (couleur primaire, accent succès, surface...), jamais de couleurs codées en dur : chaque produit branche sa propre palette sur ce contrat (KER-DES-03). |

**Convention UI recommandée — saisie téléphone (ajout 26/08/2026) :** pour tout produit du portefeuille qui fait saisir un numéro de téléphone (brique GSG ID, exigence E.164 ci-dessus), séparer indicatif pays et numéro local en deux champs distincts plutôt qu'un seul champ texte libre, et normaliser en E.164 côté client avant tout appel d'authentification. Implémentation de référence portefeuille : `PhoneInputField` dans PharmaConnect (`lib/modules/auth/widgets/phone_input_field.dart`), qui délègue la normalisation finale à une fonction unique (`normalizeE164`) plutôt que de la dupliquer par écran. Ceci reste une convention recommandée, pas une règle `KER-XXX-NN` obligatoire — si l'équipe Kernel décide d'en faire un standard portefeuille, lui attribuer un numéro selon la convention `KER-XXX-NN` ci-dessous plutôt que de l'assumer sans l'enregistrer.

### Règles d'intégration à connaître avant de coder

- **KER-INT-01** — Tout nouveau produit est conçu nativement avec le noyau dès son cahier de conception : GSG ID, `gsg_org_id`, GSG Referential et, si pertinent, le Referential Engine sont intégrés dès la première version du schéma de données, jamais ajoutés après coup.
- **KER-INT-02 / 03 / 04** — Un produit déjà en production n'est jamais contraint à une intégration a posteriori par défaut ; si la décision est prise, elle fait l'objet d'un **document de migration dédié**, jamais d'une section générique du cahier Kernel.
- **KER-ID-02 / 03** — Pour un produit déjà en production, l'intégration se fait par simple table de correspondance (`external_user_id ↔ gsg_id`) et GSG ID est proposé en option à côté du système existant, jamais en remplacement imposé.
- **KER-REF-05** — Tout montant est stocké en unité mineure entière (ex. centimes).
- **KER-NOM-01/02/03** — Convention de nommage : **français** pour le référentiel métier partagé (tables et champs), **anglais** pour l'infrastructure technique générique (services, identifiants, API — GSG ID, Event Bus, Referential Engine, AppConfig, Org Registry).
- **KER-DES-03** — Le GSG Design Kit n'expose que des **tokens sémantiques** (couleur primaire, accent succès, surface, texte secondaire...) ; jamais de valeur de couleur littérale codée en dur dans un composant partagé. Chaque produit fournit sa propre palette de marque en implémentant ce contrat de tokens (`ThemeData`/`ThemeExtension` Flutter injectée à la racine de l'app) — un produit qui a déjà un fichier de thème local avant d'adopter le Kit n'a pas à le jeter : ce fichier devient l'implémentation locale du contrat au moment de l'adoption, sans réécriture de l'UI existante qui le consomme déjà. Noms de rôles en anglais, conformément à KER-NOM-03. C'est ce qui permet à un même bouton du Design Kit d'être vert « santé » chez PharmaConnect et d'une autre teinte chez un autre produit du portefeuille, sans dupliquer les composants.

### Gabarit à reproduire dans chaque cahier produit (section « Intégration au GSG Platform Kernel »)

1. **Briques du noyau consommées** — tableau oui/non : GSG ID, Org Registry, GSG Referential, Referential Engine (avec `code_domaine`), Bus d'événements (liste publié/consommé), Audit, Billing Core (non par défaut), Design System (non par défaut).
2. **Cartographie des champs hérités du référentiel** — quels champs du schéma référencent `gsg_org_id`, `pays_id`, `devise_id`, `langue_id`, `unite_administrative_id`, `ville_id` plutôt que d'être stockés en local.
3. **Instanciation du Referential Engine** (si applicable) — `code_domaine` propre au produit, structure des arbres `referentiel_hierarchique`, `corpus_versionne` pertinents.
4. **Événements publiés et consommés** — liste + format de charge utile.
5. **État au moment de la rédaction** — produit non entamé : « conçu nativement dès l'origine » ; produit déjà en production : renvoi vers son document de migration dédié.

## Modèle d'authentification (Supabase Auth)

Document de référence pour **toute application GSG** intégrant l'authentification — remplace l'ancien schéma Firebase. Principe conservé : l'utilisateur choisit d'abord son identifiant (téléphone ou email), puis la méthode de réception du code/lien. Seule l'implémentation change de fournisseur.

### Branche Téléphone (double choix de réception)

```js
// Envoi du code (SMS ou WhatsApp)
const { error } = await supabase.auth.signInWithOtp({
  phone: '+224620000000',
  options: { channel: 'sms' } // ou 'whatsapp'
});

// Vérification du code saisi par l'utilisateur
const { data, error } = await supabase.auth.verifyOtp({
  phone: '+224620000000',
  token: '123456',
  type: 'sms'
});
```

- **SMS** : provider configuré (Twilio, MessageBird ou Vonage).
- **WhatsApp** : même appel `signInWithOtp`, avec `channel: 'whatsapp'` — nécessite un compte Twilio avec canal WhatsApp activé (numéro WhatsApp Business approuvé par Meta). Une intégration backend custom + API Meta Cloud reste possible en complément pour un contrôle total du template.

### Branche Email (gratuite et instantanée)

```js
// Magic Link (flux PKCE recommandé pour mobile/SPA)
await supabase.auth.signInWithOtp({
  email: 'user@gsg.com',
  options: { emailRedirectTo: 'https://app.gsg.com/callback' }
});

// Code OTP Email (template avec {{ .Token }})
await supabase.auth.signInWithOtp({ email: 'user@gsg.com' });
const { data, error } = await supabase.auth.verifyOtp({
  email: 'user@gsg.com',
  token: '123456',
  type: 'email'
});
```

### Correspondance Firebase → Supabase

| Branche | Firebase (origine) | Supabase (cible) |
|---|---|---|
| Téléphone – SMS | Firebase Phone Auth | Supabase Auth Phone OTP (Twilio/MessageBird/Vonage) |
| Téléphone – WhatsApp | Backend custom + API Meta | Supabase Auth Phone OTP, `channel: 'whatsapp'` (Twilio/Twilio Verify), ou Edge Function + Meta Cloud API |
| Email – Magic Link | Firebase Auth | `signInWithOtp()` → lien magique (PKCE) |
| Email – Code OTP | Firebase Auth | `signInWithOtp()` + `verifyOtp()`, template `{{ .Token }}` |

### Configuration tableau de bord Supabase (checklist)

- Authentication → Providers → Phone : activer, choisir le provider SMS (Twilio recommandé pour la couverture WhatsApp).
- Activer le canal WhatsApp dans les paramètres du provider Twilio.
- Authentication → Providers → Email : activer + personnaliser les templates (Magic Link, Email OTP).
- Configurer le rate limiting et le CAPTCHA (hCaptcha/Turnstile) pour maîtriser les coûts SMS/WhatsApp.
- Définir `emailRedirectTo` / URLs de redirection autorisées par application.

### Points de vigilance

- SMS et WhatsApp sont facturés (Twilio) ; l'email reste gratuit et instantané — à privilégier quand le contexte le permet.
- Délai par défaut : 60 s entre deux demandes, 1 h de validité du code/lien.
- Vérifier la réglementation locale sur l'envoi SMS/WhatsApp (Guinée et autres pays d'opération GSG).
- Ce modèle est la référence unique multi-app : toute nouvelle intégration Supabase Auth doit s'y conformer pour garantir une expérience homogène dans tout le portefeuille.
- **GSG ID** (SSO inter-produits) s'appuie côté produit sur Supabase Auth comme fournisseur d'identité technique sous-jacent ; les deux couches sont complémentaires, pas concurrentes.

## PharmaConnect

Infrastructure numérique du circuit pharmaceutique et des soins à domicile en Afrique de l'Ouest — trois branches (**Connect Care**, **Connect Pharma**, **Connect Supply**) sur une infrastructure unique. 34 modules fonctionnels, 66 règles de gestion. Non entamé à ce jour → conçu nativement avec le noyau dès l'origine (aucun document de migration nécessaire).

### Stack applicative

- Mobile patient + application officine en **Flutter/Dart**.
- Backend modulaire : **Rust** pour les services critiques (stock, traçabilité, paiement), **TypeScript/Node.js** pour les services applicatifs à évolution rapide (API patient, notifications).
- Base de données **Supabase** (PostgreSQL managé + réplication), fournissant nativement l'authentification (Supabase Auth), le stockage objet (Supabase Storage, avec Row Level Security) et les capacités temps réel ; complétée par **PowerSync** pour la synchronisation offline-first côté officine (zones à connectivité intermittente).
- Bus d'événements partagé (Kernel) pour stock, alertes de rappel, statut de commande.

### Intégration au Kernel — état actuel

| Brique | Statut |
|---|---|
| GSG ID | Oui — implémenté côté produit avec Supabase Auth (OTP téléphone SMS/WhatsApp, magic link, OTP email) + 2FA obligatoire pour comptes professionnels |
| Org Registry | Oui — `gsg_org_id` sur l'entité Organisation |
| GSG Referential | Oui — `pays_id`, `devise_id`, `langue_id` hérités nativement |
| Referential Engine | Oui — `code_domaine = pharmaceutique` (statut réglementaire produit, référentiel médical CEDEAO) |
| Bus d'événements | Oui — voir liste ci-dessous |
| Audit | Oui — mouvements de stock + accès aux données de santé sensibles |
| Billing Core | Non par défaut — modèle par paliers propre à PharmaConnect (KER-BIL-02) |
| Design System | Non par défaut (KER-DES-02) |

Événements publiés : `stock.seuil_atteint`, `stock.rupture`, `alerte.contrefacon`, `alerte.rappel_lot`, `commande.effectuee`, `commande.livree`, `paiement.effectue`, `paiement.reconcilie`, `kyc.officine_valide`.

> **Note (25/08/2026) — ce tableau décrit l'intention du cahier de conception, pas l'état du code.** Un audit du dépôt `pharma_connect` mené ce jour montre un écart : seule l'authentification (GSG ID via Supabase Auth) est effectivement câblée dans le code aujourd'hui ; `supabase/migrations/` est vide (aucune table, donc aucun `gsg_org_id` persisté), et aucun client de bus d'événements ni de Referential Engine n'a été trouvé dans `lib/core/kernel/`. Le produit est à un stade « prototype d'interface avec données mockées » sur la plupart des briques listées « Oui » ci-dessus, pas encore au stade décrit. Détail vivant et à jour → `pharma_connect/PharmaConnect_CLAUDE.md` ; ne pas s'appuyer sur ce tableau seul pour évaluer ce qui est réellement branché.

### Modules clés (référence rapide)

Auth (AUT), Recherche & disponibilité, Catalogue & référentiel médicaments, Stock/Lots/FEFO, Ordonnances numériques, Click & Collect, Livraison, Paiement/Mobile Money, Dashboard officine, Alertes intelligentes, Prévision de la demande, Traçabilité anti-contrefaçon, Marketplace B2B, Financement fournisseur, Télé-conseil pharmaceutique, Fidélité, Triage d'urgence, HomeCare, Réseau de professionnels mobiles, Dossier de santé numérique, Télésuivi connecté, Family & Diaspora, Intégration hôpitaux/labos, Assurance & tiers-payant, e-prescription, Multi-officines, Régulateur & pharmacovigilance, Analytics/BI, Accès solidaire, Rappels de lots, Chaîne du froid, Support client, Back-office GSG, Sécurité & conformité.

Règle de gestion critique à retenir : **RG-AUT-01** — un compte pharmacie ne peut être activé qu'après vérification de la licence auprès de la DNPM (Direction Nationale de la Pharmacie et du Médicament).

## Conventions transverses à respecter dans tout le code

- Français pour les tables/champs du référentiel métier partagé ; anglais pour l'infra technique générique.
- Montants en unité mineure entière (KER-REF-05).
- Téléphones au format E.164.
- `code_domaine` comme clé de variation structurelle par produit dans le Referential Engine (ex. `pharmaceutique` pour PharmaConnect).
- Toute évolution du noyau ajoute une ligne au registre des règles `KER-XXX-NN` plutôt que de modifier silencieusement une règle existante — même logique attendue pour les règles `RG-XXX-NN` par produit.
- Le noyau doit toujours être intégré de façon **additive** : jamais de refonte forcée d'un système d'authentification ou d'un schéma de données déjà en production.
- Tout composant UI destiné à rejoindre le futur GSG Design Kit consomme des tokens sémantiques (couleur/rôle), jamais une valeur de couleur littérale — même avant l'adoption effective du Kit, structurer le thème local d'un produit ainsi facilite une adoption sans réécriture (KER-DES-03).

## Comment utiliser ce fichier

Ce document synthétise l'état des cahiers de conception à fin août 2026. Avant toute implémentation de code touchant l'authentification, l'organisation, le référentiel pays/devise/langue ou les événements inter-produits, vérifier les règles `KER-*` correspondantes dans le cahier Kernel source plutôt que de s'appuyer uniquement sur ce résumé. Mettre à jour ce fichier à chaque évolution significative des cahiers de conception source (nouvelle version du Kernel, nouveau produit intégré, changement de fournisseur d'authentification).

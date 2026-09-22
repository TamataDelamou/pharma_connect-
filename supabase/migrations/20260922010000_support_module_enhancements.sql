-- Module 32 (SAV) : corrige C158-C163 et construit les fonctionnalites cahier
-- absentes (base de connaissances dediee, engagement de delai/SLA,
-- differenciation reelle des litiges). Schema verifie avant ecriture :
-- support_tickets a deja `priority` (low/medium/high/critical, voir
-- 20260827008000_support.sql:26) et `escalation_level` ; support_responses a
-- deja `is_internal` (20260827008000_support.sql:45) -- pas d'ajout necessaire
-- pour C162, seul le cablage UI cote Dart manquait (voir commits associes).

-- C163 : resolution_note ecrit par support_service.dart::updateTicketStatus()
-- vers une colonne qui n'existait pas.
alter table public.support_tickets add column if not exists resolution_note text;

-- SLA / engagement de delai de resolution (fonctionnalite cle n4 du cahier,
-- absente jusqu'ici -- suivi de ticket limite a un statut sans dimension
-- temporelle).
alter table public.support_tickets add column if not exists sla_due_at timestamptz;

-- Litiges (fonctionnalite cle n2 du cahier) : differenciation reelle plutot
-- qu'une simple categorie parmi d'autres sans traitement distinct.
-- dispute_reference_id sans contrainte FK inter-module -- meme convention
-- que gsg_id/gsg_org_id dans ce module (et le reste du projet), pour eviter
-- un couplage dur entre modules (une commande/un paiement/une livraison
-- peuvent vivre dans des tables de modules differents). Type `text` plutot
-- que `uuid` (ajustement par rapport a la demande initiale) : c'est un
-- patient qui saisit cette reference a la main (numero de commande affiche
-- a l'ecran, reference de paiement...), jamais garanti d'etre un UUID
-- valide -- `uuid` aurait fait echouer l'insertion sur toute saisie non-UUID
-- (`invalid input syntax for type uuid`), ce qui aurait recree exactement
-- le defaut C160 (categories mockees envoyees vers une colonne uuid) sur un
-- champ neuf.
alter table public.support_tickets add column if not exists is_dispute boolean not null default false;
alter table public.support_tickets add column if not exists dispute_category text
  check (dispute_category in ('order', 'payment', 'delivery'));
alter table public.support_tickets add column if not exists disputed_amount numeric;
alter table public.support_tickets add column if not exists dispute_reference_id text;

-- Calcul du SLA a la creation du ticket selon la priorite. Choix du trigger
-- SQL plutot que du calcul cote service Dart : c'est deja le mecanisme
-- retenu dans ce meme fichier pour une autre valeur calculee a l'insertion
-- (generate_ticket_number(), trigger_support_tickets_number ci-dessus) --
-- coherence avec l'existant plutot qu'un deuxieme mecanisme parallele cote
-- client. `if new.sla_due_at is null` laisse la possibilite d'un override
-- explicite (ex. import, tests) sans casser le calcul par defaut.
create or replace function public.set_support_ticket_sla()
returns trigger as $$
begin
  if new.sla_due_at is null then
    new.sla_due_at := new.created_at + case new.priority
      when 'critical' then interval '24 hours'
      when 'high' then interval '24 hours'
      when 'medium' then interval '48 hours'
      when 'low' then interval '72 hours'
      else interval '48 hours'
    end;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_support_tickets_sla
before insert on public.support_tickets
for each row execute function public.set_support_ticket_sla();

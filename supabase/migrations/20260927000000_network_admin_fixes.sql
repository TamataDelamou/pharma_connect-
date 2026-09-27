-- Correctif C132 : log_network_activity() (20260829007000_network_admin.sql)
-- est declenche AFTER INSERT/UPDATE/DELETE sur public.pharmacies et
-- public.profiles et ecrit auth.uid() dans network_activity_log.admin_user_id,
-- colonne declaree NOT NULL. Or auth.uid() vaut NULL pour toute ecriture
-- faite sans session utilisateur :
--   - seed.sql (supabase start / db reset) ;
--   - service_role (Edge Functions, scripts d'administration) ;
--   - tout autre traitement systeme sans JWT utilisateur.
-- Dans chacun de ces cas, l'insertion dans network_activity_log echouait
-- (SQLSTATE 23502) et faisait echouer l'ecriture d'origine avec elle.
-- Constate le 27/09/2026 par execution locale de la chaine complete
-- (supabase start : 92 migrations appliquees, echec au chargement de seed.sql).
--
-- Correctif retenu : admin_user_id devient nullable. Une ligne de journal
-- sans admin_user_id signifie « action systeme, sans session ». La migration
-- d'origine n'est pas modifiee (elle peut deja etre appliquee ailleurs).

alter table public.network_activity_log alter column admin_user_id drop not null;

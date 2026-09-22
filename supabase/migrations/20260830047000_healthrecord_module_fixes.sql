-- Audit Module 20 (DSN), clôture (30/08/2026) — correctif ponctuel décidé
-- par le porteur du projet indépendamment de l'arbitrage retenu pour
-- C95/D33 et RG-DSN-01/RG-DSN-02/D34.
--
-- C96 : `20260827003000_health_records.sql` ne définissait aucune policy
-- `delete` pour `health_records` (seules select/update/insert existaient
-- côté patient). Confirmé bloquant en pratique par exécution réelle sur
-- Postgres 16 (Étape 3, protocole identique à C78/C82-C93) : un patient
-- authentifié qui supprime sa propre ligne obtient `DELETE 0` — aucune
-- erreur, aucun refus d'autorisation — et la ligne persiste en base.
-- `HealthRecordProvider.deleteRecord` ne remonte alors aucune exception,
-- l'écran affiche donc un succès alors que la donnée de santé du patient
-- n'a jamais été supprimée. Corrigé par l'ajout de la policy manquante,
-- symétrique aux policies select/update/insert déjà en place (patient
-- propriétaire de sa propre fiche).
create policy "Patients can delete own records" on public.health_records
  for delete using (auth.uid() = patient_id);

-- Module prescriptions (lib/modules/prescriptions). Ordonnances numériques
-- et OCR. `e_prescription.dart` (EPrescription) n'a pas de table : ce modèle
-- n'est câblé à aucun service/provider/écran du dépôt (grep ne trouve aucun
-- usage hors de sa propre définition) — lui créer un schéma serait spéculatif.

create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references auth.users(id),
  patient_name text not null,
  doctor_name text,
  doctor_license text,
  uploaded_at timestamptz not null default now(),
  validated_at timestamptz,
  dispensed_at timestamptz,
  status text not null default 'draft' check (status in (
    'draft', 'pending', 'validated', 'dispensed', 'archived'
  )),
  image_url text not null,
  ocr_data jsonb,
  notes text,
  ocr_confidence_score numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.prescriptions is 'Ordonnances numériques (prescriptions/models/prescription.dart).';

create index if not exists idx_prescriptions_patient_id on public.prescriptions(patient_id);
create index if not exists idx_prescriptions_status on public.prescriptions(status);

create trigger set_updated_at
  before update on public.prescriptions
  for each row execute function public.set_updated_at();

create table if not exists public.prescription_items (
  id uuid primary key default gen_random_uuid(),
  prescription_id uuid not null references public.prescriptions(id) on delete cascade,
  medication_name text not null,
  dosage text not null,
  frequency text not null,
  duration text not null,
  quantity integer not null,
  instructions text,
  is_substitution_allowed boolean not null default false,
  suggested_generic_id uuid references public.products(id),
  is_extracted_by_ocr boolean not null default false,
  ocr_confidence numeric not null default 0
);

comment on table public.prescription_items is 'Lignes d''une ordonnance (prescriptions/models/prescription_item.dart).';

create index if not exists idx_prescription_items_prescription_id on public.prescription_items(prescription_id);

alter table public.prescriptions enable row level security;
alter table public.prescription_items enable row level security;

-- Donnée de santé sensible (KER audit — accès aux données de santé) :
-- lecture strictement limitée au patient propriétaire. Un accès pharmacien/
-- staff nécessitera une politique dédiée une fois qu'un mécanisme de
-- vérification de rôle existera (ex. table de correspondance utilisateur ↔
-- officine) — pas de règle inventée ici sans ce fondement.
create policy "prescriptions_select_own" on public.prescriptions
  for select to authenticated
  using (auth.uid() = patient_id);

create policy "prescription_items_select_own" on public.prescription_items
  for select to authenticated
  using (
    exists (
      select 1 from public.prescriptions p
      where p.id = prescription_items.prescription_id
        and p.patient_id = auth.uid()
    )
  );

-- Family challenges
create table public.family_challenges (
  id uuid primary key default gen_random_uuid(),
  family_link_id uuid not null references public.family_links(id) on delete cascade,
  challenge_type text not null check (challenge_type in ('steps', 'water', 'fruits', 'meditation', 'consultations')),
  target_value integer not null,
  progress integer default 0,
  status text default 'active' check (status in ('active', 'completed', 'expired')),
  deadline_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Family challenge contributions (per member)
create table public.family_challenge_contributions (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.family_challenges(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  contribution_value integer default 0,
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(challenge_id, patient_id)
);

-- Family activities log (shared journal)
create table public.family_activities (
  id uuid primary key default gen_random_uuid(),
  family_link_id uuid not null references public.family_links(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  activity_type text not null, -- 'walk', 'water', 'fruits', 'meditation', 'consultation', 'medication'
  value numeric,
  note text,
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_family_challenges_link_id on public.family_challenges(family_link_id);
create index idx_family_challenges_status on public.family_challenges(status);
create index idx_family_challenge_contributions_challenge on public.family_challenge_contributions(challenge_id);
create index idx_family_activities_link_id on public.family_activities(family_link_id);
create index idx_family_activities_patient_id on public.family_activities(patient_id);

-- Triggers for updated_at
create trigger trigger_family_challenges_updated_at
before update on public.family_challenges
for each row execute function public.update_updated_at();

-- RLS
alter table public.family_challenges enable row level security;
alter table public.family_challenge_contributions enable row level security;
alter table public.family_activities enable row level security;

-- Family members view challenges
create policy "Family members view challenges" on public.family_challenges
  for select using (
    exists (
      select 1 from public.family_links
      where id = family_link_id and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );

-- Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-1 (complément) :
-- `family_challenges` n'avait qu'une policy `select` — `createChallenge()`/
-- `updateProgress()`/`deleteChallenge()` (`FamilyChallengeProvider`) sont
-- pourtant des écritures réelles côté client. Même motif que family_alerts/
-- family_activity_log (voir `20260827005000_family.sql`), trouvé une
-- seconde fois dans une migration adjacente du même territoire de module.
create policy "Family members manage challenges" on public.family_challenges
  for all using (
    exists (
      select 1 from public.family_links
      where id = family_link_id and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );

-- Family members update contributions
create policy "Family members update contributions" on public.family_challenge_contributions
  for all using (
    exists (
      select 1 from public.family_links
      where id = (select family_link_id from public.family_challenges where id = challenge_id)
      and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );

-- Family members view activities
create policy "Family members view activities" on public.family_activities
  for select using (
    exists (
      select 1 from public.family_links
      where id = family_link_id and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );

-- Family members insert activities
create policy "Family members insert activities" on public.family_activities
  for insert with check (
    exists (
      select 1 from public.family_links
      where id = family_link_id and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );

-- Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-1 (complément) :
-- `deleteFamilyActivity()` (`FamilyChallengeProvider`) est un appel réel
-- côté client, sans policy `delete` correspondante — même motif que
-- ci-dessus.
create policy "Family members delete activities" on public.family_activities
  for delete using (
    exists (
      select 1 from public.family_links
      where id = family_link_id and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );

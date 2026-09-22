-- Async messaging between patients and professionals
create table public.async_messages (
  id uuid primary key default gen_random_uuid(),
  consultation_id uuid references public.consultations(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message text not null,
  attachments text[],
  is_read boolean default false,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_async_messages_patient_id on public.async_messages(patient_id);
create index idx_async_messages_professional_id on public.async_messages(professional_id);
create index idx_async_messages_sender_id on public.async_messages(sender_id);
create index idx_async_messages_is_read on public.async_messages(is_read);

-- RLS
alter table public.async_messages enable row level security;

-- Participants can view messages
create policy "Participants view messages" on public.async_messages
  for select using (auth.uid() in (patient_id, professional_id));

-- Participants send messages
create policy "Participants send messages" on public.async_messages
  for insert with check (auth.uid() in (patient_id, professional_id));

-- Sender can update their own messages
create policy "Sender update messages" on public.async_messages
  for update using (auth.uid() = sender_id);

-- Sender can delete their own messages
create policy "Sender delete messages" on public.async_messages
  for delete using (auth.uid() = sender_id);

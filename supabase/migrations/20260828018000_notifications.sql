-- Notification history
create table notifications_history (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  channel text not null check (channel in ('sms', 'whatsapp', 'email', 'push')),
  notification_type text not null,
  title text,
  message text not null,
  status text default 'sent' check (status in ('sent', 'delivered', 'failed')),
  sent_at timestamptz not null default now(),
  delivered_at timestamptz,
  error_message text,
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table public.notifications_history enable row level security;

-- Patients view own notification history
create policy "Patients view own notification history" on public.notifications_history
  for select using (auth.uid() = patient_id);

-- Staff view patient notifications
create policy "Staff view notifications" on public.notifications_history
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

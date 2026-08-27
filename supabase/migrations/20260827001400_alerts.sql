-- Module alerts (lib/modules/alerts). Alertes intelligentes et préférences
-- de notification.

create table if not exists public.alerts (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in (
    'stockLow', 'stockCritical', 'stockOut', 'expirySoon', 'expired',
    'counterfeit', 'recall', 'orderConfirmed', 'orderDelivered', 'orderDelayed',
    'paymentSuccess', 'paymentFailed', 'paymentDisputed', 'refundProcessed',
    'prescriptionReceived', 'prescriptionValidated', 'prescriptionDispensed',
    'reservationReady', 'reservationPickedUp', 'reservationExpired',
    'deliveryStarted', 'deliveryArrived', 'deliveryCompleted',
    'system', 'promotion', 'reminder'
  )),
  severity text not null check (severity in ('critical', 'warning', 'info', 'success')),
  status text not null default 'new' check (status in ('new', 'read', 'dismissed', 'actioned')),
  title text not null,
  message text not null,
  action_label text,
  action_route text,
  action_params jsonb,
  reference_id text,
  reference_type text,
  read_at timestamptz,
  actioned_at timestamptz,
  user_id uuid references auth.users(id),
  pharmacy_id uuid references public.pharmacies(id),
  is_read boolean not null default false,
  is_actioned boolean not null default false,
  image_url text,
  created_at timestamptz not null default now()
);

comment on table public.alerts is 'Alertes intelligentes (alerts/models/alert.dart). status ''new'' remplace le AlertStatus.new_ Dart (underscore = contournement de mot réservé côté Dart uniquement).';

create index if not exists idx_alerts_user_id on public.alerts(user_id);
create index if not exists idx_alerts_pharmacy_id on public.alerts(pharmacy_id);
create index if not exists idx_alerts_created_at on public.alerts(created_at desc);

create table if not exists public.alert_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  email_enabled boolean not null default true,
  in_app_enabled boolean not null default true,
  sound_enabled boolean not null default true,
  type_enabled jsonb not null default '{}',
  severity_enabled jsonb not null default '{"critical": true, "warning": true, "info": true, "success": true}',
  updated_at timestamptz not null default now()
);

comment on table public.alert_preferences is 'Préférences de notification par utilisateur (alerts/models/alert_preferences.dart).';

create trigger set_updated_at
  before update on public.alert_preferences
  for each row execute function public.set_updated_at();

alter table public.alerts enable row level security;
alter table public.alert_preferences enable row level security;

create policy "alerts_select_own" on public.alerts
  for select to authenticated
  using (auth.uid() = user_id);

create policy "alerts_update_own" on public.alerts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "alert_preferences_select_own" on public.alert_preferences
  for select to authenticated
  using (auth.uid() = user_id);

create policy "alert_preferences_upsert_own" on public.alert_preferences
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "alert_preferences_update_own" on public.alert_preferences
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

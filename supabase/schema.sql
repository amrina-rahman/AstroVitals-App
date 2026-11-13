create table if not exists public.users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  astronaut_id text not null unique,
  full_name text not null,
  email text not null,
  date_of_birth date not null,
  height_cm double precision not null check (height_cm > 0),
  current_weight_kg double precision not null check (current_weight_kg > 0),
  gender text,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists "Users can read their own profile" on public.users;
create policy "Users can read their own profile"
  on public.users for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own profile" on public.users;
create policy "Users can create their own profile"
  on public.users for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own profile" on public.users;
create policy "Users can update their own profile"
  on public.users for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create table if not exists public.health_records (
  record_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (user_id) on delete cascade,
  metric_type text not null,
  value jsonb not null,
  unit text not null,
  source_type text not null check (
    source_type in ('manual', 'simulated_smartwatch')
  ),
  device_id text,
  recorded_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.health_records
  add column if not exists device_id text;

create index if not exists health_records_user_metric_time_idx
  on public.health_records (user_id, metric_type, recorded_at desc);

alter table public.health_records enable row level security;

drop policy if exists "Users can read their own health records"
  on public.health_records;
create policy "Users can read their own health records"
  on public.health_records for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own health records"
  on public.health_records;
create policy "Users can create their own health records"
  on public.health_records for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

do $$
begin
  alter publication supabase_realtime add table public.health_records;
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.daily_activity (
  activity_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (user_id) on delete cascade,
  steps integer check (steps >= 0),
  water_intake_ml integer check (water_intake_ml >= 0),
  sleep_duration_hours double precision check (
    sleep_duration_hours between 0 and 24
  ),
  exercise_duration_minutes integer check (exercise_duration_minutes >= 0),
  weight_kg double precision check (weight_kg > 0),
  recorded_date date not null,
  recorded_at timestamptz not null default now(),
  source_type text not null check (
    source_type in ('manual', 'simulated_smartwatch')
  ),
  created_at timestamptz not null default now(),
  unique (user_id, recorded_date, source_type)
);

alter table public.daily_activity
  add column if not exists weight_kg double precision,
  add column if not exists recorded_at timestamptz not null default now();

create index if not exists daily_activity_user_date_idx
  on public.daily_activity (user_id, recorded_date desc);

create unique index if not exists daily_activity_user_date_source_key
  on public.daily_activity (user_id, recorded_date, source_type);

alter table public.daily_activity enable row level security;

drop policy if exists "Users can read their own daily activity"
  on public.daily_activity;
create policy "Users can read their own daily activity"
  on public.daily_activity for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own daily activity"
  on public.daily_activity;
create policy "Users can create their own daily activity"
  on public.daily_activity for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own daily activity"
  on public.daily_activity;
create policy "Users can update their own daily activity"
  on public.daily_activity for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

do $$
begin
  alter publication supabase_realtime add table public.daily_activity;
exception
  when duplicate_object then null;
end
$$;

grant select, insert on public.health_records to authenticated;
grant select, insert, update on public.daily_activity to authenticated;
grant select, insert, update on public.users to authenticated;

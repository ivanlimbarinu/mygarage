-- Run once in Supabase SQL Editor, or apply with Supabase CLI migrations.
begin;
create table if not exists public.garage_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  profile jsonb not null check (jsonb_typeof(profile) = 'object'),
  updated_at timestamptz not null default now()
);
create table if not exists public.garage_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null check (
    jsonb_typeof(state) = 'object' and
    state ?& array['vehicles', 'deadlines', 'fuelCost', 'maintenance', 'refills'] and
    jsonb_typeof(state->'vehicles') = 'array' and
    jsonb_array_length(state->'vehicles') > 0 and
    jsonb_typeof(state->'deadlines') = 'array'
  ),
  updated_at timestamptz not null default now()
);
alter table public.garage_profiles add column if not exists updated_at timestamptz not null default now();
alter table public.garage_states add column if not exists updated_at timestamptz not null default now();
alter table public.garage_profiles enable row level security;
alter table public.garage_states enable row level security;
revoke all on public.garage_profiles, public.garage_states from anon;
grant select, insert, update, delete on public.garage_profiles, public.garage_states to authenticated;
drop policy if exists own_profile on public.garage_profiles;
create policy own_profile on public.garage_profiles for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists own_state on public.garage_states;
create policy own_state on public.garage_states for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create or replace function public.garage_touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists profile_updated on public.garage_profiles;
create trigger profile_updated before update on public.garage_profiles
  for each row execute function public.garage_touch_updated_at();
drop trigger if exists state_updated on public.garage_states;
create trigger state_updated before update on public.garage_states
  for each row execute function public.garage_touch_updated_at();
commit;

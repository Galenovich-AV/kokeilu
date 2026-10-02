-- Suomi-muistikirja: database for the Netlify site.
-- Run once in Supabase → SQL Editor → New query → Run.

create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.results (
  user_id uuid not null references auth.users on delete cascade,
  key text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

create table if not exists public.feedback (
  user_id uuid not null references auth.users on delete cascade,
  key text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

create table if not exists public.teachers (
  user_id uuid primary key references auth.users on delete cascade
);

create or replace function public.is_teacher() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.teachers where user_id = auth.uid());
$$;

alter table public.profiles enable row level security;
alter table public.results  enable row level security;
alter table public.feedback enable row level security;
alter table public.teachers enable row level security;

-- students: only their own rows; teacher: reads everything, writes feedback
drop policy if exists "profiles read"  on public.profiles;
drop policy if exists "profiles write" on public.profiles;
drop policy if exists "profiles update" on public.profiles;
create policy "profiles read"   on public.profiles for select using (id = auth.uid() or public.is_teacher());
create policy "profiles write"  on public.profiles for insert with check (id = auth.uid());
create policy "profiles update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "results read"   on public.results;
drop policy if exists "results write"  on public.results;
drop policy if exists "results update" on public.results;
create policy "results read"   on public.results for select using (user_id = auth.uid() or public.is_teacher());
create policy "results write"  on public.results for insert with check (user_id = auth.uid());
create policy "results update" on public.results for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "feedback read"   on public.feedback;
drop policy if exists "feedback write"  on public.feedback;
drop policy if exists "feedback update" on public.feedback;
create policy "feedback read"   on public.feedback for select using (user_id = auth.uid() or public.is_teacher());
create policy "feedback write"  on public.feedback for insert with check (public.is_teacher());
create policy "feedback update" on public.feedback for update using (public.is_teacher()) with check (public.is_teacher());

-- nobody reads or writes teachers from the site; is_teacher() checks it

-- AFTER you have registered on the site yourself, make yourself the teacher
-- (replace the email and run this line on its own):
-- insert into public.teachers (user_id) select id from auth.users where email = 'YOUR_EMAIL';

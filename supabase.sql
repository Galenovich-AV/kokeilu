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

-- ---------------------------------------------------------------
-- Teacher tools (run this part once more if you set up the database earlier):
-- the student list with e-mail and registration date, and deleting a student
-- ---------------------------------------------------------------
create or replace function public.teacher_students()
returns table (id uuid, name text, email text, created_at timestamptz, updated_at timestamptz)
language sql stable security definer set search_path = public as $$
  select u.id, coalesce(p.name, u.raw_user_meta_data->>'name', ''), u.email::text, u.created_at, p.updated_at
  from auth.users u left join public.profiles p on p.id = u.id
  where public.is_teacher() and u.id not in (select user_id from public.teachers)
  order by u.created_at desc;
$$;

create or replace function public.delete_student(uid uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_teacher() then raise exception 'only the teacher can delete students'; end if;
  if exists (select 1 from public.teachers where user_id = uid) then raise exception 'a teacher cannot be deleted here'; end if;
  delete from auth.users where id = uid;  -- profiles, results and feedback go with it (on delete cascade)
end $$;

revoke all on function public.teacher_students() from public, anon;
revoke all on function public.delete_student(uuid) from public, anon;
grant execute on function public.teacher_students() to authenticated;
grant execute on function public.delete_student(uuid) to authenticated;

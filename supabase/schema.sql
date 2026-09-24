-- Profiles are created for authenticated users. Role changes must be performed
-- by a protected server/admin function, never directly from the browser.
create type public.app_role as enum ('candidate', 'recruiter', 'admin');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.app_role not null default 'candidate',
  created_at timestamptz not null default now()
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  recruiter_id uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  cv_path text,
  status text not null default 'submitted',
  created_at timestamptz not null default now(),
  unique(candidate_id, job_id)
);

alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;

-- A user may read their own profile. Admin access is added through a server-side
-- function or a separate policy after verifying the JWT role claim.
create policy "read own profile" on public.profiles
for select to authenticated using (id = auth.uid());

create policy "candidate creates own application" on public.applications
for insert to authenticated with check (candidate_id = auth.uid());

create policy "candidate reads own applications" on public.applications
for select to authenticated using (candidate_id = auth.uid());

create policy "recruiter reads assigned job applications" on public.applications
for select to authenticated using (
  exists (
    select 1 from public.jobs j
    where j.id = applications.job_id and j.recruiter_id = auth.uid()
  )
);

-- Store CVs in a private bucket. A candidate can access only objects whose first
-- path segment is their authenticated user id.
insert into storage.buckets (id, name, public) values ('candidate-cvs', 'candidate-cvs', false)
on conflict (id) do nothing;

create policy "candidate uploads own CV" on storage.objects
for insert to authenticated with check (
  bucket_id = 'candidate-cvs' and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "candidate reads own CV" on storage.objects
for select to authenticated using (
  bucket_id = 'candidate-cvs' and (storage.foldername(name))[1] = auth.uid()::text
);

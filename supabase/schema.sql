-- Nowshera Digital ATS schema. Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;
create schema if not exists private;
do $$ begin create type public.app_role as enum ('candidate','recruiter','admin'); exception when duplicate_object then null; end $$;
do $$ begin create type public.application_status as enum ('submitted','reviewing','shortlisted','interview','rejected','hired'); exception when duplicate_object then null; end $$;
create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 role public.app_role not null default 'candidate',
 created_at timestamptz not null default now()
);
create table if not exists public.jobs(
 id uuid primary key default gen_random_uuid(),
 title text not null,
 department text not null default 'General',
 location text not null default 'Nowshera · Hybrid',
 type text not null default 'Full-time',
 description text not null default '',
 recruiter_id uuid references public.profiles(id) on delete set null,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.applications(
 id uuid primary key default gen_random_uuid(),
 candidate_id uuid not null references public.profiles(id) on delete cascade,
 job_id uuid not null references public.jobs(id) on delete cascade,
 cv_path text not null,
 status public.application_status not null default 'submitted',
 created_at timestamptz not null default now(),
 unique(candidate_id,job_id)
);
-- A narrowly scoped definer helper avoids recursive profile RLS. Role changes are not available to users.
create or replace function private.current_app_role()
returns public.app_role language sql stable security definer set search_path=''
as $$ select p.role from public.profiles p where p.id = (select auth.uid()) $$;
revoke all on function private.current_app_role() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.current_app_role() to authenticated;
create or replace function public.create_candidate_profile()
returns trigger language plpgsql security definer set search_path=''
as $$ begin
 insert into public.profiles(id,full_name,role)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''), 'candidate')
 on conflict(id) do nothing;
 return new;
end $$;
revoke all on function public.create_candidate_profile() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users for each row execute function public.create_candidate_profile();
alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;
grant select on public.jobs to anon,authenticated;
grant select,insert,update on public.profiles to authenticated;
grant select,insert,update,delete on public.jobs to authenticated;
grant select,insert,update,delete on public.applications to authenticated;
drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using(id=(select auth.uid()) or (select private.current_app_role())='admin');
create policy "admin manages profiles" on public.profiles for update to authenticated using((select private.current_app_role())='admin') with check((select private.current_app_role()) in ('admin','recruiter','candidate'));
create policy "public sees active jobs" on public.jobs for select to anon,authenticated using(is_active or (select private.current_app_role())='admin' or recruiter_id=(select auth.uid()));
create policy "admin creates jobs" on public.jobs for insert to authenticated with check((select private.current_app_role())='admin');
create policy "admin updates jobs" on public.jobs for update to authenticated using((select private.current_app_role())='admin') with check((select private.current_app_role())='admin');
create policy "admin deletes jobs" on public.jobs for delete to authenticated using((select private.current_app_role())='admin');
drop policy if exists "candidate reads own applications" on public.applications;
create policy "candidate and assigned staff read applications" on public.applications for select to authenticated using(candidate_id=(select auth.uid()) or (select private.current_app_role())='admin' or exists(select 1 from public.jobs j where j.id=applications.job_id and j.recruiter_id=(select auth.uid())));
create policy "candidate submits own application" on public.applications for insert to authenticated with check(candidate_id=(select auth.uid()) and exists(select 1 from public.jobs j where j.id=job_id and j.is_active));
create policy "assigned staff updates status" on public.applications for update to authenticated using((select private.current_app_role())='admin' or exists(select 1 from public.jobs j where j.id=applications.job_id and j.recruiter_id=(select auth.uid()))) with check((select private.current_app_role())='admin' or exists(select 1 from public.jobs j where j.id=applications.job_id and j.recruiter_id=(select auth.uid())));
create policy "admin removes applications" on public.applications for delete to authenticated using((select private.current_app_role())='admin');
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('candidate-cvs','candidate-cvs',false,8388608,array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document']) on conflict(id) do update set public=false,file_size_limit=8388608,allowed_mime_types=excluded.allowed_mime_types;
create policy "candidate uploads own CV" on storage.objects for insert to authenticated with check(bucket_id='candidate-cvs' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "candidate and assigned staff read CVs" on storage.objects for select to authenticated using(bucket_id='candidate-cvs' and ((storage.foldername(name))[1]=(select auth.uid())::text or (select private.current_app_role())='admin' or exists(select 1 from public.applications a join public.jobs j on j.id=a.job_id where a.cv_path=name and j.recruiter_id=(select auth.uid()))));
create policy "candidate replaces own CV" on storage.objects for update to authenticated using(bucket_id='candidate-cvs' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='candidate-cvs' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "admin deletes CVs" on storage.objects for delete to authenticated using(bucket_id='candidate-cvs' and (select private.current_app_role())='admin');
-- Seed initial jobs. Replace/edit these from the admin dashboard or SQL Editor.
insert into public.jobs(title,department,location,type,description) values
('Frontend Developer','Engineering','Nowshera · Hybrid','Full-time','Build thoughtful digital experiences with a collaborative product team.'),
('People Operations Associate','People','Nowshera · On-site','Full-time','Help our teams do their best work through welcoming, organized operations.'),
('Product Designer','Design','Remote · Pakistan','Contract','Turn complex workflows into clear and useful product experiences.'),
('Customer Success Specialist','Operations','Nowshera · Hybrid','Full-time','Partner with customers and make every interaction feel effortless.')
on conflict do nothing;

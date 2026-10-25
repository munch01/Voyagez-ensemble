-- Cap: schema initial pour Supabase (à exécuter dans l'éditeur SQL du projet).
create extension if not exists pgcrypto;

create table public.trips (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  destination text,
  start_date date,
  end_date date,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trip_dates_valid check (start_date is null or end_date is null or end_date >= start_date)
);

create table public.trip_members (
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text,
  role text not null default 'editor' check (role in ('owner','editor')),
  created_at timestamptz not null default now(),
  primary key (trip_id,user_id)
);

create table public.trip_invitations (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  email text not null,
  invited_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (trip_id,email)
);

create table public.stops (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  address text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  description text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint stop_times_valid check (ends_at >= starts_at),
  constraint stop_latitude_valid check (latitude is null or latitude between -90 and 90),
  constraint stop_longitude_valid check (longitude is null or longitude between -180 and 180)
);
create index stops_trip_start_idx on public.stops(trip_id,starts_at);

create table public.stop_attachments (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  stop_id uuid not null references public.stops(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  content_type text not null,
  file_size bigint not null check (file_size between 1 and 20971520),
  created_at timestamptz not null default now()
);
create index stop_attachments_stop_idx on public.stop_attachments(stop_id);

create or replace function public.is_trip_member(check_trip_id uuid)
returns boolean language sql stable security definer set search_path = public, auth
as $$
  select exists (
    select 1 from public.trip_members
    where trip_id = check_trip_id and user_id = (select auth.uid())
  );
$$;

create or replace function public.add_trip_owner()
returns trigger language plpgsql security definer set search_path = public, auth
as $$
begin
  insert into public.trip_members(trip_id,user_id,email,role)
  values (new.id,new.owner_id,lower(auth.jwt()->>'email'),'owner');
  return new;
end;
$$;
create trigger trips_add_owner after insert on public.trips
for each row execute function public.add_trip_owner();

create or replace function public.prevent_trip_owner_change()
returns trigger language plpgsql set search_path = public
as $$
begin
  if new.owner_id <> old.owner_id then
    raise exception 'Le propriétaire du voyage ne peut pas être modifié.';
  end if;
  new.updated_at = now();
  return new;
end;
$$;
create trigger trips_prevent_owner_change before update on public.trips
for each row execute function public.prevent_trip_owner_change();

create or replace function public.accept_trip_invitations()
returns integer language plpgsql security definer set search_path = public, auth
as $$
declare
  current_email text := lower(auth.jwt()->>'email');
  accepted integer;
begin
  if auth.uid() is null or current_email is null then
    raise exception 'Une session avec une adresse e-mail vérifiée est requise.';
  end if;
  insert into public.trip_members(trip_id,user_id,email,role)
  select invitation.trip_id,auth.uid(),current_email,'editor'
  from public.trip_invitations invitation
  where lower(invitation.email)=current_email
  on conflict (trip_id,user_id) do nothing;
  get diagnostics accepted = row_count;
  delete from public.trip_invitations where lower(email)=current_email;
  return accepted;
end;
$$;

alter table public.trips enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_invitations enable row level security;
alter table public.stops enable row level security;
alter table public.stop_attachments enable row level security;

create policy "Members can read trips" on public.trips for select to authenticated
using (public.is_trip_member(id));
create policy "Users can create trips for themselves" on public.trips for insert to authenticated
with check (owner_id = (select auth.uid()));
create policy "Members can update trips" on public.trips for update to authenticated
using (public.is_trip_member(id)) with check (public.is_trip_member(id));
create policy "Owners can delete trips" on public.trips for delete to authenticated
using (owner_id = (select auth.uid()));

create policy "Members can read trip members" on public.trip_members for select to authenticated
using (public.is_trip_member(trip_id));
create policy "Members can read invitations" on public.trip_invitations for select to authenticated
using (public.is_trip_member(trip_id) or lower(email)=lower(auth.jwt()->>'email'));
create policy "Members can invite collaborators" on public.trip_invitations for insert to authenticated
with check (public.is_trip_member(trip_id) and invited_by=(select auth.uid()));
create policy "Invitees or members can remove invitations" on public.trip_invitations for delete to authenticated
using (public.is_trip_member(trip_id) or lower(email)=lower(auth.jwt()->>'email'));

create policy "Members can read stops" on public.stops for select to authenticated
using (public.is_trip_member(trip_id));
create policy "Members can add stops" on public.stops for insert to authenticated
with check (public.is_trip_member(trip_id));
create policy "Members can update stops" on public.stops for update to authenticated
using (public.is_trip_member(trip_id)) with check (public.is_trip_member(trip_id));
create policy "Members can delete stops" on public.stops for delete to authenticated
using (public.is_trip_member(trip_id));

create policy "Members can read attachment records" on public.stop_attachments for select to authenticated
using (public.is_trip_member(trip_id));
create policy "Members can add attachment records" on public.stop_attachments for insert to authenticated
with check (
  public.is_trip_member(trip_id)
  and exists (
    select 1 from public.stops s
    where s.id=public.stop_attachments.stop_id
      and s.trip_id=public.stop_attachments.trip_id
  )
  and split_part(public.stop_attachments.storage_path,'/',1)=public.stop_attachments.trip_id::text
  and split_part(public.stop_attachments.storage_path,'/',2)=public.stop_attachments.stop_id::text
);
create policy "Members can delete attachment records" on public.stop_attachments for delete to authenticated
using (public.is_trip_member(trip_id));

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('trip-files','trip-files',false,20971520,array['application/pdf','image/png','image/jpeg','image/webp','image/heic','text/plain'])
on conflict (id) do update set public=false,file_size_limit=20971520,allowed_mime_types=excluded.allowed_mime_types;

create policy "Trip members can read private trip files" on storage.objects for select to authenticated
using (bucket_id='trip-files' and public.is_trip_member((storage.foldername(name))[1]::uuid));
create policy "Trip members can upload private trip files" on storage.objects for insert to authenticated
with check (bucket_id='trip-files' and public.is_trip_member((storage.foldername(name))[1]::uuid));
create policy "Trip members can delete private trip files" on storage.objects for delete to authenticated
using (bucket_id='trip-files' and public.is_trip_member((storage.foldername(name))[1]::uuid));

grant execute on function public.accept_trip_invitations() to authenticated;

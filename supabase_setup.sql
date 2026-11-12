-- Sonia tailoring gallery: database and storage setup
-- Run this once in the Supabase SQL Editor while signed in as the project owner.

create table if not exists public.gallery_categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (owner_id, name)
);

create table if not exists public.gallery_photos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  category text not null default 'هەموو وێنەکان',
  storage_path text not null,
  favorite boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.owner_platforms (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  url text,
  storage_path text not null,
  created_at timestamptz not null default now()
);

alter table public.gallery_categories enable row level security;
alter table public.gallery_photos enable row level security;
alter table public.owner_platforms enable row level security;

revoke all on public.gallery_categories from anon, authenticated;
revoke all on public.gallery_photos from anon, authenticated;
revoke all on public.owner_platforms from anon, authenticated;
grant select on public.gallery_categories, public.gallery_photos to anon, authenticated;
grant insert, update, delete on public.gallery_categories, public.gallery_photos to authenticated;
grant select, insert, update, delete on public.owner_platforms to authenticated;

drop policy if exists "Public can view gallery categories" on public.gallery_categories;
create policy "Public can view gallery categories"
  on public.gallery_categories for select to anon, authenticated using (true);
drop policy if exists "Owner manages gallery categories" on public.gallery_categories;
create policy "Owner manages gallery categories"
  on public.gallery_categories for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists "Public can view gallery photos" on public.gallery_photos;
create policy "Public can view gallery photos"
  on public.gallery_photos for select to anon, authenticated using (true);
drop policy if exists "Owner manages gallery photos" on public.gallery_photos;
create policy "Owner manages gallery photos"
  on public.gallery_photos for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists "Owner manages private platforms" on public.owner_platforms;
create policy "Owner manages private platforms"
  on public.owner_platforms for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

insert into storage.buckets (id, name, public)
values ('sonia-gallery', 'sonia-gallery', true)
on conflict (id) do update set public = true;
insert into storage.buckets (id, name, public)
values ('sonia-owner-private', 'sonia-owner-private', false)
on conflict (id) do update set public = false;

drop policy if exists "Owner uploads gallery photos" on storage.objects;
create policy "Owner uploads gallery photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'sonia-gallery'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner updates gallery photos" on storage.objects;
create policy "Owner updates gallery photos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'sonia-gallery'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'sonia-gallery'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner deletes gallery photos" on storage.objects;
create policy "Owner deletes gallery photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'sonia-gallery'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "Owner reads private platform images" on storage.objects;
create policy "Owner reads private platform images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'sonia-owner-private'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner uploads private platform images" on storage.objects;
create policy "Owner uploads private platform images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'sonia-owner-private'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner updates private platform images" on storage.objects;
create policy "Owner updates private platform images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'sonia-owner-private'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'sonia-owner-private'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner deletes private platform images" on storage.objects;
create policy "Owner deletes private platform images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'sonia-owner-private'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );


-- Public social platform links and icons. Only the signed-in owner can add/change/remove rows.
alter table public.owner_platforms
  add column if not exists is_public boolean not null default false,
  add column if not exists storage_bucket text not null default 'sonia-owner-private';

grant select on public.owner_platforms to anon, authenticated;
drop policy if exists "Public can view shared platform links" on public.owner_platforms;
create policy "Public can view shared platform links"
  on public.owner_platforms for select to anon, authenticated
  using (is_public = true);

insert into storage.buckets (id, name, public)
values ('sonia-platform-public', 'sonia-platform-public', true)
on conflict (id) do update set public = true;

drop policy if exists "Anyone can view public platform images" on storage.objects;
create policy "Anyone can view public platform images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'sonia-platform-public');
drop policy if exists "Owner uploads public platform images" on storage.objects;
create policy "Owner uploads public platform images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'sonia-platform-public'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner updates public platform images" on storage.objects;
create policy "Owner updates public platform images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'sonia-platform-public'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'sonia-platform-public'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
drop policy if exists "Owner deletes public platform images" on storage.objects;
create policy "Owner deletes public platform images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'sonia-platform-public'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
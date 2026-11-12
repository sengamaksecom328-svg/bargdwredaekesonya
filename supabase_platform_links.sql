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
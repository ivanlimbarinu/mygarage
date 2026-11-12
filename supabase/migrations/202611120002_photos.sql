begin;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('garage-photos', 'garage-photos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists garage_photos_owner on storage.objects;
create policy garage_photos_owner on storage.objects
for all to authenticated
using (bucket_id = 'garage-photos' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'garage-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
commit;

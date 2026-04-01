# Supabase Storage para imágenes de productos

## Bucket requerido

- Nombre: `product-images`
- Público: `true`

## Crear bucket (SQL Editor)

```sql
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;
```

## Políticas recomendadas (lectura pública + escritura autenticada)

```sql
create policy if not exists "product_images_public_read"
on storage.objects
for select
to public
using (bucket_id = 'product-images');

create policy if not exists "product_images_authenticated_insert"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'product-images');
```

> Si usas `SUPABASE_SERVICE_ROLE_KEY` en servidor, la escritura no depende de RLS,
> pero estas políticas ayudan para uploads desde clientes autenticados.

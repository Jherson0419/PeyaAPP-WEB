-- Crea automáticamente un perfil en public."Profile" al registrarse un usuario en Supabase Auth.
-- Ejecuta este script en el SQL Editor de Supabase.

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public."Profile" (
    id,
    email,
    full_name,
    phone,
    role,
    vehicle_type,
    plate_number,
    is_online
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'phone',
    coalesce((new.raw_user_meta_data ->> 'role')::"ProfileRole", 'CLIENT'::"ProfileRole"),
    case
      when coalesce((new.raw_user_meta_data ->> 'role')::"ProfileRole", 'CLIENT'::"ProfileRole") = 'RIDER'::"ProfileRole"
        then new.raw_user_meta_data ->> 'vehicle_type'
      else null
    end,
    case
      when coalesce((new.raw_user_meta_data ->> 'role')::"ProfileRole", 'CLIENT'::"ProfileRole") = 'RIDER'::"ProfileRole"
        then new.raw_user_meta_data ->> 'plate_number'
      else null
    end,
    false
  )
  on conflict (id) do nothing;

  return new;
exception
  when invalid_text_representation then
    -- Si role viene con valor inválido, usa CLIENT por defecto.
    insert into public."Profile" (
      id,
      email,
      full_name,
      phone,
      role,
      vehicle_type,
      plate_number,
      is_online
    )
    values (
      new.id,
      new.email,
      coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
      new.raw_user_meta_data ->> 'phone',
      'CLIENT'::"ProfileRole",
      null,
      null,
      false
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;

create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_user_profile();

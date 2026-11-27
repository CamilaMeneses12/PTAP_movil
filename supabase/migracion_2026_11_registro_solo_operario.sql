-- ==============================================================================
-- MIGRACIÓN 2026-11: toda cuenta creada desde "Crear cuenta" entra como operario
-- Antes el rol se tomaba de los datos que envía el celular al registrarse, así que
-- cualquiera podía crearse una cuenta de administrador. Ahora el rol siempre es
-- 'operario'; otro rol solo lo asigna un administrador desde la app o desde Supabase.
-- Ejecutar UNA VEZ en Supabase › SQL Editor. Es seguro ejecutarla de nuevo.
-- No cambia el rol de las cuentas que ya existen.
-- ==============================================================================

create or replace function public.manejar_nuevo_usuario()
returns trigger as $$
begin
    insert into public.perfiles (id, nombre_completo, correo, rol)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'nombre_completo', split_part(new.email, '@', 1)),
        new.email,
        'operario'
    )
    on conflict (id) do update set
        correo = excluded.correo,
        nombre_completo = coalesce(excluded.nombre_completo, public.perfiles.nombre_completo);
    return new;
end;
$$ language plpgsql security definer;

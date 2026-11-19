-- ==============================================================================
-- MIGRACIÓN 2026-11: perfiles por rol, umbrales editables y lectura de medidores con cámara
-- Ejecutar UNA VEZ en Supabase › SQL Editor sobre la base de datos ya creada con schema.sql.
-- Es seguro ejecutarla de nuevo: todo usa "if not exists" / "on conflict".
-- ==============================================================================

-- 1. UMBRALES OPERATIVOS (caudal, presión, nivel) editables desde el Perfil del administrador
alter table public.rangos_parametros drop constraint if exists rangos_parametros_seccion_check;
alter table public.rangos_parametros add constraint rangos_parametros_seccion_check
    check (seccion in ('agua_cruda', 'agua_filtrada', 'agua_clorada', 'puntos_control', 'operacion'));

insert into public.rangos_parametros (seccion, parametro, nombre_visible, unidad, valor_minimo, valor_maximo, norma_referencia) values
    ('operacion', 'caudal_entrada', 'Caudal de entrada', 'L/s', 110.0, 140.0, 'Control operativo PTAP'),
    ('operacion', 'caudal_salida', 'Caudal de salida', 'L/s', 105.0, 135.0, 'Control operativo PTAP'),
    ('operacion', 'presion_red', 'Presión de red', 'bar', 2.8, 4.0, 'Control operativo PTAP'),
    ('operacion', 'nivel_tanque', 'Nivel mínimo de tanque', '%', 40.0, null, 'Control operativo PTAP')
on conflict (seccion, parametro) do nothing;

-- 2. REGISTROS GUARDADOS CON AVISO DE FUERA DE RANGO (la app ya envía estas columnas)
alter table public.jornadas_medidores add column if not exists fuera_de_rango boolean not null default false;
alter table public.aforos_caudal add column if not exists fuera_de_rango boolean not null default false;

-- 3. LECTURA DE MICROMEDIDORES CON CÁMARA (OCR)
-- Cantidad de rodillos del contador: negros = m³ enteros, rojos = decimales
alter table public.medidores add column if not exists digitos_enteros integer not null default 4;
alter table public.medidores add column if not exists digitos_decimales integer not null default 4;
alter table public.medidores alter column digitos_enteros set default 4;
alter table public.medidores alter column digitos_decimales set default 4;
-- Los micromedidores instalados tienen 4 rodillos blancos (m³) + 4 rojos (decimales): 0813,6267
update public.medidores set digitos_enteros = 4, digitos_decimales = 4
    where tipo = 'micromedidor' and digitos_enteros = 5 and digitos_decimales = 3;

alter table public.lecturas_medidores add column if not exists foto_url text;
alter table public.lecturas_medidores add column if not exists metodo_lectura text not null default 'manual';
alter table public.lecturas_medidores add column if not exists fuera_de_rango boolean not null default false;
alter table public.lecturas_medidores drop constraint if exists lecturas_medidores_metodo_lectura_check;
alter table public.lecturas_medidores add constraint lecturas_medidores_metodo_lectura_check
    check (metodo_lectura in ('manual', 'camara_ocr', 'ocr_editado'));

comment on column public.lecturas_medidores.foto_url is 'Ruta de la foto de evidencia en el bucket lecturas-medidores';
comment on column public.lecturas_medidores.metodo_lectura is 'manual | camara_ocr (valor leído por la cámara) | ocr_editado (leído y corregido por el operario)';

-- 4. BUCKET PRIVADO PARA LAS FOTOS DE EVIDENCIA
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('lecturas-medidores', 'lecturas-medidores', false, 1048576, array['image/jpeg'])
on conflict (id) do nothing;

drop policy if exists "Ver fotos de lecturas de medidores" on storage.objects;
create policy "Ver fotos de lecturas de medidores"
    on storage.objects for select
    to authenticated
    using (bucket_id = 'lecturas-medidores');

drop policy if exists "Operario y admin suben fotos de lecturas" on storage.objects;
create policy "Operario y admin suben fotos de lecturas"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'lecturas-medidores' and public.obtener_rol_actual() in ('operario', 'administrador'));

drop policy if exists "Operario y admin reemplazan fotos de lecturas" on storage.objects;
create policy "Operario y admin reemplazan fotos de lecturas"
    on storage.objects for update
    to authenticated
    using (bucket_id = 'lecturas-medidores' and public.obtener_rol_actual() in ('operario', 'administrador'));

drop policy if exists "Solo admin elimina fotos de lecturas" on storage.objects;
create policy "Solo admin elimina fotos de lecturas"
    on storage.objects for delete
    to authenticated
    using (bucket_id = 'lecturas-medidores' and public.obtener_rol_actual() = 'administrador');

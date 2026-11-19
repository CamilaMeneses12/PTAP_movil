-- ==============================================================================
-- PLANTA DE TRATAMIENTO DE AGUA POTABLE (PTAP) - SENA
-- Esquema de Base de Datos PostgreSQL / Supabase
-- Formato fuente: DO-F-070 (Calidad del Agua) y Tabla Caudal Quebrada La Seca
-- ==============================================================================

-- 1. EXTENSIONES
create extension if not exists "uuid-ossp";

-- 2. TABLA DE PERFILES (Extensión de auth.users con Roles)
-- Roles: 'operario', 'administrador', 'consultor_siga'
create table if not exists public.perfiles (
    id uuid references auth.users(id) on delete cascade primary key,
    nombre_completo text not null,
    correo text not null,
    rol text not null check (rol in ('operario', 'administrador', 'consultor_siga')) default 'operario',
    activo boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Comentarios
comment on table public.perfiles is 'Perfiles de usuario y asignación de roles de la planta de agua SENA';
comment on column public.perfiles.rol is 'Rol en el sistema: operario (registra en campo), administrador (gestiona todo), consultor_siga (solo lectura y reportes)';

-- 3. FUNCIÓN Y TRIGGER PARA CREACIÓN AUTOMÁTICA DE PERFIL AL REGISTRARSE
create or replace function public.manejar_nuevo_usuario()
returns trigger as $$
begin
    insert into public.perfiles (id, nombre_completo, correo, rol)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'nombre_completo', split_part(new.email, '@', 1)),
        new.email,
        coalesce(new.raw_user_meta_data->>'rol', 'operario')
    )
    on conflict (id) do update set
        correo = excluded.correo,
        nombre_completo = coalesce(excluded.nombre_completo, public.perfiles.nombre_completo);
    return new;
end;
$$ language plpgsql security definer;

-- Trigger sobre auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.manejar_nuevo_usuario();

-- 4. FUNCIÓN AUXILIAR DE SEGURIDAD PARA CONSULTAR EL ROL DEL USUARIO ACTUAL
create or replace function public.obtener_rol_actual()
returns text as $$
    select rol from public.perfiles where id = auth.uid();
$$ language sql stable security definer;

-- 5. TABLA: PUNTOS DE MUESTREO (Catálogo de áreas de red de distribución)
create table if not exists public.puntos_muestreo (
    id bigserial primary key,
    nombre text not null unique,
    descripcion text,
    activo boolean not null default true,
    created_at timestamptz not null default now(),
    created_by uuid references public.perfiles(id)
);

-- 6. TABLA: RANGOS Y LÍMITES NORMATIVOS (Resolución 2115 de 2007)
create table if not exists public.rangos_parametros (
    id bigserial primary key,
    seccion text not null check (seccion in ('agua_cruda', 'agua_filtrada', 'agua_clorada', 'puntos_control', 'operacion')),
    parametro text not null,
    nombre_visible text not null,
    unidad text not null,
    valor_minimo numeric(8,2),
    valor_maximo numeric(8,2),
    norma_referencia text default 'Resolución 2115 de 2007',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uk_seccion_parametro unique (seccion, parametro)
);

-- 7. TABLA: REGISTROS FISICOQUÍMICOS (Formato DO-F-070)
create table if not exists public.registros_fisicoquimicos (
    id uuid primary key default gen_random_uuid(),
    fecha date not null default current_date,
    hora time not null default current_time,
    regional text not null default 'Distrito Capital',
    centro_formacion text not null default 'Centro de Tecnologías Agroindustriales',
    sede text not null default 'Sede Principal',
    
    -- Agua Cruda
    cruda_caudal_entrada numeric(10,2), -- L/s
    cruda_ph numeric(4,2),              -- 5.0 - 9.0
    cruda_turbidez numeric(10,2),        -- máx 10 UJT
    cruda_color numeric(10,2),           -- máx 20 UPC
    cruda_dureza numeric(10,2),          -- mg/L CaCO3
    cruda_dosis_coagulante text,         -- mg/L o indicación test de jarras
    
    -- Agua Filtrada
    filtrada_turbidez numeric(10,2),     -- 0.0 - 2.0 NTU
    filtrada_ph numeric(4,2),           -- 6.5 - 9.0
    
    -- Agua Clorada
    clorada_turbidez numeric(10,2),      -- 0.0 - 2.0 NTU
    clorada_ph numeric(4,2),            -- 6.5 - 9.0
    clorada_color_aparente numeric(10,2),-- máx 15 UPC
    clorada_cloro_residual numeric(5,2), -- 0.3 - 2.0 mg/L
    
    -- Control y trazabilidad
    observaciones text,
    responsable_nombre text,
    fuera_de_rango boolean not null default false,
    created_by uuid references public.perfiles(id) not null default auth.uid(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 8. TABLA: MEDICIONES EN PUNTOS DE CONTROL (Red interna por cada registro diario)
create table if not exists public.puntos_control_mediciones (
    id uuid primary key default gen_random_uuid(),
    registro_fisicoquimico_id uuid references public.registros_fisicoquimicos(id) on delete cascade not null,
    punto_muestreo_id bigint references public.puntos_muestreo(id),
    area_nombre text not null,
    turbidez numeric(10,2),              -- 0.0 - 2.0 NTU
    ph numeric(4,2),                     -- 6.5 - 9.0
    color_aparente numeric(10,2),        -- máx 15 UPC
    cloro_residual numeric(5,2),         -- 0.3 - 2.0 mg/L
    fuera_de_rango boolean not null default false,
    observacion text,
    created_by uuid references public.perfiles(id) not null default auth.uid(),
    created_at timestamptz not null default now()
);

-- 9. TABLA: CATÁLOGO DE MEDIDORES
create table if not exists public.medidores (
    id bigserial primary key,
    codigo text unique not null,
    nombre text not null,
    tipo text not null check (tipo in ('micromedidor', 'macromedidor')),
    orden integer not null default 0,
    activo boolean not null default true,
    created_at timestamptz not null default now(),
    created_by uuid references public.perfiles(id)
);

-- 10. TABLA: JORNADAS DE MEDIDORES (Ronda diaria de lecturas)
create table if not exists public.jornadas_medidores (
    id uuid primary key default gen_random_uuid(),
    fecha date not null default current_date,
    hora time not null default current_time,
    responsable_lectura text,
    observaciones text,
    consumo_total_micros numeric(12,4) not null default 0,
    consumo_macromedidor numeric(12,4) not null default 0,
    agua_no_registrada numeric(12,4) not null default 0,
    created_by uuid references public.perfiles(id) not null default auth.uid(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 11. TABLA: LECTURAS INDIVIDUALES POR MEDIDOR
create table if not exists public.lecturas_medidores (
    id uuid primary key default gen_random_uuid(),
    jornada_id uuid references public.jornadas_medidores(id) on delete cascade not null,
    medidor_id bigint references public.medidores(id) not null,
    lectura_actual numeric(12,4) not null,
    lectura_anterior numeric(12,4) not null default 0,
    consumo numeric(12,4) not null default 0,
    created_by uuid references public.perfiles(id) not null default auth.uid(),
    created_at timestamptz not null default now()
);

-- 12. TABLA: AFOROS DE CAUDAL QUEBRADA LA SECA (Método del Flotador)
create table if not exists public.aforos_caudal (
    id uuid primary key default gen_random_uuid(),
    fecha date not null default current_date,
    hora time not null default current_time,
    
    -- Parámetros medidos
    ancho_cauce_m numeric(8,3) not null,          -- Ancho del cauce (m)
    profundidad_1_m numeric(8,3) not null,        -- Profundidad 1 (m)
    profundidad_2_m numeric(8,3) not null,        -- Profundidad 2 (m)
    profundidad_3_m numeric(8,3) not null,        -- Profundidad 3 (m)
    profundidad_4_m numeric(8,3) not null,        -- Profundidad 4 (m)
    distancia_flotador_m numeric(8,3) not null,   -- Distancia recorrida por flotador (m)
    tiempo_1_s numeric(8,2) not null,             -- Tiempo 1 (s)
    tiempo_2_s numeric(8,2) not null,             -- Tiempo 2 (s)
    tiempo_3_s numeric(8,2) not null,             -- Tiempo 3 (s)
    tiempo_4_s numeric(8,2) not null,             -- Tiempo 4 (s)
    factor_correccion numeric(4,2) not null default 0.80, -- Coeficiente de velocidad
    
    -- Valores calculados automáticamente (fórmulas del Excel)
    profundidad_promedio_m numeric(8,4) not null, -- Promedio de las 4 profundidades
    area_seccion_m2 numeric(10,5) not null,       -- Ancho * Profundidad promedio
    tiempo_promedio_s numeric(8,4) not null,      -- Promedio de los 4 tiempos
    velocidad_superficial_m_s numeric(10,5) not null, -- Distancia / Tiempo promedio
    velocidad_corregida_m_s numeric(10,5) not null,   -- Velocidad superficial * 0.8
    caudal_m3_s numeric(12,6) not null,           -- Área * Velocidad corregida
    caudal_m3_h numeric(12,4) not null,           -- Caudal m3/s * 3600
    caudal_l_s numeric(12,4) not null,            -- Caudal m3/s * 1000
    caudal_l_h numeric(14,2) not null,            -- Caudal L/s * 3600
    
    observaciones text,
    created_by uuid references public.perfiles(id) not null default auth.uid(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- ==============================================================================
-- 13. POLÍTICAS DE SEGURIDAD RLS (ROW LEVEL SECURITY)
-- ==============================================================================

alter table public.perfiles enable row level security;
alter table public.puntos_muestreo enable row level security;
alter table public.rangos_parametros enable row level security;
alter table public.registros_fisicoquimicos enable row level security;
alter table public.puntos_control_mediciones enable row level security;
alter table public.medidores enable row level security;
alter table public.jornadas_medidores enable row level security;
alter table public.lecturas_medidores enable row level security;
alter table public.aforos_caudal enable row level security;

-- PERFILES
create policy "Usuarios autenticados pueden ver perfiles"
    on public.perfiles for select
    to authenticated
    using (true);

create policy "Usuarios pueden actualizar su propio perfil o admin actualiza cualquiera"
    on public.perfiles for update
    to authenticated
    using (id = auth.uid() or public.obtener_rol_actual() = 'administrador');

-- CATÁLOGOS (puntos_muestreo, medidores, rangos_parametros)
-- Consulta: Cualquier usuario autenticado
create policy "Ver puntos de muestreo"
    on public.puntos_muestreo for select
    to authenticated
    using (true);

create policy "Admin gestiona puntos de muestreo"
    on public.puntos_muestreo for all
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

create policy "Ver medidores"
    on public.medidores for select
    to authenticated
    using (true);

create policy "Admin gestiona medidores"
    on public.medidores for all
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

create policy "Ver rangos de parametros"
    on public.rangos_parametros for select
    to authenticated
    using (true);

create policy "Admin gestiona rangos"
    on public.rangos_parametros for all
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

-- REGISTROS OPERATIVOS: REGISTROS FISICOQUÍMICOS
create policy "Lectura de registros fisicoquimicos"
    on public.registros_fisicoquimicos for select
    to authenticated
    using (true);

create policy "Operario y Admin insertan registros fisicoquimicos"
    on public.registros_fisicoquimicos for insert
    to authenticated
    with check (public.obtener_rol_actual() in ('operario', 'administrador'));

create policy "Operario edita sus propios registros o Admin edita cualquiera"
    on public.registros_fisicoquimicos for update
    to authenticated
    using (created_by = auth.uid() or public.obtener_rol_actual() = 'administrador');

create policy "Solo admin elimina registros fisicoquimicos"
    on public.registros_fisicoquimicos for delete
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

-- MEDICIONES PUNTOS DE CONTROL
create policy "Lectura de mediciones puntos de control"
    on public.puntos_control_mediciones for select
    to authenticated
    using (true);

create policy "Operario y Admin insertan mediciones puntos de control"
    on public.puntos_control_mediciones for insert
    to authenticated
    with check (public.obtener_rol_actual() in ('operario', 'administrador'));

create policy "Operario edita sus mediciones o Admin cualquiera"
    on public.puntos_control_mediciones for update
    to authenticated
    using (created_by = auth.uid() or public.obtener_rol_actual() = 'administrador');

create policy "Solo admin elimina mediciones de puntos de control"
    on public.puntos_control_mediciones for delete
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

-- JORNADAS DE MEDIDORES
create policy "Lectura de jornadas de medidores"
    on public.jornadas_medidores for select
    to authenticated
    using (true);

create policy "Operario y Admin insertan jornadas de medidores"
    on public.jornadas_medidores for insert
    to authenticated
    with check (public.obtener_rol_actual() in ('operario', 'administrador'));

create policy "Operario edita sus jornadas o Admin cualquiera"
    on public.jornadas_medidores for update
    to authenticated
    using (created_by = auth.uid() or public.obtener_rol_actual() = 'administrador');

create policy "Solo admin elimina jornadas de medidores"
    on public.jornadas_medidores for delete
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

-- LECTURAS INDIVIDUALES DE MEDIDORES
create policy "Lectura de lecturas individuales"
    on public.lecturas_medidores for select
    to authenticated
    using (true);

create policy "Operario y Admin insertan lecturas"
    on public.lecturas_medidores for insert
    to authenticated
    with check (public.obtener_rol_actual() in ('operario', 'administrador'));

create policy "Operario edita sus lecturas o Admin cualquiera"
    on public.lecturas_medidores for update
    to authenticated
    using (created_by = auth.uid() or public.obtener_rol_actual() = 'administrador');

create policy "Solo admin elimina lecturas"
    on public.lecturas_medidores for delete
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

-- AFOROS DE CAUDAL QUEBRADA LA SECA
create policy "Lectura de aforos de caudal"
    on public.aforos_caudal for select
    to authenticated
    using (true);

create policy "Operario y Admin insertan aforos"
    on public.aforos_caudal for insert
    to authenticated
    with check (public.obtener_rol_actual() in ('operario', 'administrador'));

create policy "Operario edita sus aforos o Admin cualquiera"
    on public.aforos_caudal for update
    to authenticated
    using (created_by = auth.uid() or public.obtener_rol_actual() = 'administrador');

create policy "Solo admin elimina aforos"
    on public.aforos_caudal for delete
    to authenticated
    using (public.obtener_rol_actual() = 'administrador');

-- ==============================================================================
-- 14. DATOS SEMILLA (SEED DATA BASADO EN LOS FORMATOS REALES)
-- ==============================================================================

-- Medidores oficiales del formato
insert into public.medidores (codigo, nombre, tipo, orden) values
    ('MIC-01', 'ENCC', 'micromedidor', 1),
    ('MIC-02', 'SENNOVA', 'micromedidor', 2),
    ('MIC-03', 'LABORATORIOS', 'micromedidor', 3),
    ('MIC-04', 'BIOCABAÑA', 'micromedidor', 4),
    ('MIC-05', 'CAFETERIA', 'micromedidor', 5),
    ('MIC-06', 'PECUARIA', 'micromedidor', 6),
    ('MIC-07', 'AGROINDUSTRIA', 'micromedidor', 7),
    ('MIC-08', 'GASTRONOMIA', 'micromedidor', 8),
    ('MAC-01', 'MACRO MEDIDOR', 'macromedidor', 9)
on conflict (codigo) do nothing;

-- Puntos de muestreo oficiales del formato
insert into public.puntos_muestreo (nombre, descripcion) values
    ('Biocabaña', 'Punto de muestreo en red Biocabaña'),
    ('Agroindustria', 'Punto de muestreo en red Agroindustria'),
    ('Gastronomia', 'Punto de muestreo en red Gastronomía'),
    ('ENCC', 'Punto de muestreo en red ENCC'),
    ('Dispensador Bienestar', 'Dispensador de agua Bienestar al Aprendiz')
on conflict (nombre) do nothing;

-- Rangos normativos oficiales según Resolución 2115 de 2007 y DO-F-070
insert into public.rangos_parametros (seccion, parametro, nombre_visible, unidad, valor_minimo, valor_maximo, norma_referencia) values
    -- Agua Cruda
    ('agua_cruda', 'ph', 'pH Agua Cruda', 'pH', 5.0, 9.0, 'DO-F-070'),
    ('agua_cruda', 'turbidez', 'Turbidez Entrada', 'UJT', 0.0, 10.0, 'DO-F-070'),
    ('agua_cruda', 'color', 'Color Agua Cruda', 'UPC', 0.0, 20.0, 'DO-F-070'),
    
    -- Agua Filtrada
    ('agua_filtrada', 'ph', 'pH Agua Filtrada', 'pH', 6.5, 9.0, 'Res. 2115/2007'),
    ('agua_filtrada', 'turbidez', 'Turbidez Agua Filtrada', 'NTU', 0.0, 2.0, 'Res. 2115/2007'),
    
    -- Agua Clorada
    ('agua_clorada', 'ph', 'pH Agua Clorada', 'pH', 6.5, 9.0, 'Res. 2115/2007'),
    ('agua_clorada', 'turbidez', 'Turbidez Agua Clorada', 'NTU', 0.0, 2.0, 'Res. 2115/2007'),
    ('agua_clorada', 'color_aparente', 'Color Aparente Clorada', 'UPC', 0.0, 15.0, 'Res. 2115/2007'),
    ('agua_clorada', 'cloro_residual', 'Cloro Residual Libre', 'mg/L', 0.3, 2.0, 'Res. 2115/2007'),
    
    -- Puntos de Control
    ('puntos_control', 'ph', 'pH Punto de Control', 'pH', 6.5, 9.0, 'Res. 2115/2007'),
    ('puntos_control', 'turbidez', 'Turbidez Punto de Control', 'NTU', 0.0, 2.0, 'Res. 2115/2007'),
    ('puntos_control', 'color_aparente', 'Color Aparente', 'UPC', 0.0, 15.0, 'Res. 2115/2007'),
    ('puntos_control', 'cloro_residual', 'Cloro Residual Libre', 'mg/L', 0.3, 2.0, 'Res. 2115/2007')
on conflict (seccion, parametro) do update set
    valor_minimo = excluded.valor_minimo,
    valor_maximo = excluded.valor_maximo,
    updated_at = now();

-- ==============================================================================
-- 15. AMPLIACIONES 2026-11 (umbrales operativos, avisos fuera de rango, cámara OCR)
-- Para una base de datos ya existente, ejecute supabase/migracion_2026_11_perfiles_y_camara.sql
-- ==============================================================================

-- 15.1 UMBRALES OPERATIVOS (caudal, presión, nivel) editables desde el Perfil del administrador
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
alter table public.medidores add column if not exists digitos_enteros integer not null default 5;
alter table public.medidores add column if not exists digitos_decimales integer not null default 3;

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

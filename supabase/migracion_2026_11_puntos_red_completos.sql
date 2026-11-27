-- ==============================================================================
-- MIGRACIÓN 2026-11: todos los puntos de control en red del DO-F-070
-- El formato traía solo 5 puntos. Se agregan las áreas que faltaban para que coincidan
-- con los 8 micromedidores de la sede (más el dispensador de Bienestar).
-- Ejecutar UNA VEZ en Supabase › SQL Editor. Es seguro ejecutarla de nuevo.
-- ==============================================================================

insert into public.puntos_muestreo (nombre, descripcion) values
    ('SENNOVA', 'Punto de muestreo en red SENNOVA'),
    ('Laboratorios', 'Punto de muestreo en red Laboratorios'),
    ('Cafetería', 'Punto de muestreo en red Cafetería'),
    ('Pecuaria', 'Punto de muestreo en red Pecuaria')
on conflict (nombre) do nothing;

-- ==============================================================================
-- MIGRACIÓN 2026-11: quitar el caudal de salida y la presión de red
-- La operaria de la planta indicó que ninguno de los dos se puede medir ni calcular con
-- precisión en la PTAP, así que la app ya no los muestra ni los valida.
-- Ejecutar UNA VEZ en Supabase › SQL Editor. Es seguro ejecutarla de nuevo.
-- ==============================================================================

delete from public.rangos_parametros
where seccion = 'operacion'
  and parametro in ('caudal_salida', 'presion_red');

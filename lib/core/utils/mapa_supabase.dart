final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Prepara un mapa para insertarlo en Supabase.
///
/// La app crea registros con identificadores locales ('jornada-1700000000') que no son UUID;
/// Postgres los rechaza en columnas `uuid`. Se quitan `id` y `created_by` cuando no son UUID
/// para que la base de datos use sus valores por defecto (gen_random_uuid() y auth.uid()).
Map<String, dynamic> paraInsertarEnSupabase(Map<String, dynamic> mapa) {
  final copia = Map<String, dynamic>.of(mapa);
  for (final campo in const ['id', 'created_by']) {
    final valor = copia[campo];
    if (valor is! String || !_uuid.hasMatch(valor)) copia.remove(campo);
  }
  return copia;
}

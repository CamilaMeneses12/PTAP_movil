import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/local/almacen_local.dart';
import 'package:planta_agua/data/local/cache_sincronizable.dart';

/// Configuración común de todas las pruebas: cada prueba empieza con el almacén del celular
/// vacío y en memoria (sin archivos), para que los datos de una no se filtren a otra.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    AlmacenLocal.instancia = AlmacenMemoria();
    CacheSincronizable.reiniciar();
  });
  await testMain();
}

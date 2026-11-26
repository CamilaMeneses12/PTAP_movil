import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda datos en el celular para que la app funcione sin internet.
abstract class AlmacenLocal {
  /// Almacén que usa toda la app. Las pruebas lo reemplazan por [AlmacenMemoria].
  static AlmacenLocal instancia = AlmacenArchivos();

  Future<List<Map<String, dynamic>>> leerLista(String coleccion);
  Future<void> guardarLista(String coleccion, List<Map<String, dynamic>> datos);

  Future<Map<String, dynamic>?> leerObjeto(String clave);
  Future<void> guardarObjeto(String clave, Map<String, dynamic>? datos);

  /// Carpeta donde se copian las fotos de las lecturas mientras no se suben; null si no hay.
  Future<Directory?> carpetaFotos();
}

/// Almacén en memoria (pruebas o celular sin acceso a archivos).
class AlmacenMemoria implements AlmacenLocal {
  final Map<String, String> _datos = {};

  @override
  Future<List<Map<String, dynamic>>> leerLista(String coleccion) async {
    final t = _datos['lista_$coleccion'];
    if (t == null) return [];
    return (jsonDecode(t) as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> guardarLista(String coleccion, List<Map<String, dynamic>> datos) async =>
      _datos['lista_$coleccion'] = jsonEncode(datos);

  @override
  Future<Map<String, dynamic>?> leerObjeto(String clave) async {
    final t = _datos['obj_$clave'];
    return t == null ? null : jsonDecode(t) as Map<String, dynamic>;
  }

  @override
  Future<void> guardarObjeto(String clave, Map<String, dynamic>? datos) async {
    if (datos == null) {
      _datos.remove('obj_$clave');
    } else {
      _datos['obj_$clave'] = jsonEncode(datos);
    }
  }

  @override
  Future<Directory?> carpetaFotos() async => null;
}

/// Almacén en archivos JSON dentro de la carpeta privada de la app.
/// Si el celular no permite escribir, sigue funcionando en memoria.
class AlmacenArchivos implements AlmacenLocal {
  final AlmacenMemoria _respaldo = AlmacenMemoria();
  Future<Directory?>? _carpeta;
  Future<void> _escrituras = Future.value();

  Future<Directory?> _directorio() => _carpeta ??= () async {
        try {
          final base = await getApplicationDocumentsDirectory();
          final dir = Directory('${base.path}${Platform.pathSeparator}ptap_local');
          await dir.create(recursive: true);
          return dir;
        } catch (e) {
          debugPrint('Almacén local no disponible, se usa memoria: $e');
          return null;
        }
      }();

  Future<File?> _archivo(String nombre) async {
    final dir = await _directorio();
    return dir == null ? null : File('${dir.path}${Platform.pathSeparator}$nombre.json');
  }

  Future<String?> _leer(String nombre) async {
    final f = await _archivo(nombre);
    if (f == null || !await f.exists()) return null;
    try {
      return await f.readAsString();
    } catch (e) {
      debugPrint('No se pudo leer $nombre: $e');
      return null;
    }
  }

  /// Escribe en un archivo temporal y lo renombra: un corte a mitad no deja el archivo dañado.
  /// Las escrituras van en fila para que dos guardados seguidos no se pisen.
  Future<void> _escribir(String nombre, String? contenido) {
    _escrituras = _escrituras.then((_) async {
      final f = await _archivo(nombre);
      if (f == null) return;
      try {
        if (contenido == null) {
          if (await f.exists()) await f.delete();
          return;
        }
        final tmp = File('${f.path}.tmp');
        await tmp.writeAsString(contenido, flush: true);
        await tmp.rename(f.path);
      } catch (e) {
        debugPrint('No se pudo guardar $nombre en el celular: $e');
      }
    });
    return _escrituras;
  }

  @override
  Future<List<Map<String, dynamic>>> leerLista(String coleccion) async {
    if (await _directorio() == null) return _respaldo.leerLista(coleccion);
    final t = await _leer('lista_$coleccion');
    if (t == null) return [];
    try {
      return (jsonDecode(t) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Archivo local $coleccion dañado: $e');
      return [];
    }
  }

  @override
  Future<void> guardarLista(String coleccion, List<Map<String, dynamic>> datos) async {
    if (await _directorio() == null) return _respaldo.guardarLista(coleccion, datos);
    await _escribir('lista_$coleccion', jsonEncode(datos));
  }

  @override
  Future<Map<String, dynamic>?> leerObjeto(String clave) async {
    if (await _directorio() == null) return _respaldo.leerObjeto(clave);
    final t = await _leer('obj_$clave');
    if (t == null) return null;
    try {
      return jsonDecode(t) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> guardarObjeto(String clave, Map<String, dynamic>? datos) async {
    if (await _directorio() == null) return _respaldo.guardarObjeto(clave, datos);
    await _escribir('obj_$clave', datos == null ? null : jsonEncode(datos));
  }

  @override
  Future<Directory?> carpetaFotos() async {
    final dir = await _directorio();
    if (dir == null) return null;
    final fotos = Directory('${dir.path}${Platform.pathSeparator}fotos');
    await fotos.create(recursive: true);
    return fotos;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/core/utils/identificador.dart';
import 'package:planta_agua/core/utils/mapa_supabase.dart';
import 'package:planta_agua/data/local/almacen_local.dart';
import 'package:planta_agua/data/local/cache_sincronizable.dart';
import 'package:planta_agua/data/local/serializacion_local.dart';
import 'package:planta_agua/data/models/alerta_sistema_modelo.dart';
import 'package:planta_agua/data/models/medidores_modelos.dart';
import 'package:planta_agua/data/models/registro_fisicoquimico.dart';
import 'package:planta_agua/data/repositories/fisicoquimico_repository.dart';
import 'package:planta_agua/data/repositories/medidores_repository.dart';
import 'package:planta_agua/data/services/foto_lectura_service.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/common/providers/sincronizacion_provider.dart';
import 'package:planta_agua/presentation/common/widgets/aviso_sincronizacion.dart';
import 'package:planta_agua/presentation/flow/providers/caudal_provider.dart';
import 'package:planta_agua/presentation/meters/providers/medidores_provider.dart';
import 'package:planta_agua/presentation/physicochemical/providers/fisicoquimico_provider.dart';

RegistroFisicoquimico _registro(String id) => RegistroFisicoquimico(
      id: id,
      fecha: DateTime(2026, 11, 25),
      hora: '07:30',
      cloradaCloroResidual: 1.1,
      puntosControl: const [MedicionPuntoControl(areaNombre: 'Biocabaña', ph: 7.4)],
      responsableNombre: 'Karol',
      createdBy: 'karol',
      createdAt: DateTime(2026, 11, 25, 7, 31),
    );

CacheSincronizable<RegistroFisicoquimico> _cache() => CacheSincronizable.de<RegistroFisicoquimico>(
      'pruebas',
      aMapa: SerializacionLocal.fisicoquimicoAMapa,
      deMapa: SerializacionLocal.fisicoquimicoDeMapa,
      idDe: (r) => r.id,
    );

void main() {
  test('UUID v4: válido para Supabase, así un reintento no duplica el registro', () {
    final a = generarUuid();
    expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(generarUuid(), isNot(a));
    expect(paraInsertarEnSupabase({'id': a})['id'], a);
  });

  group('Cache sincronizable', () {
    test('Lo pendiente sobrevive a cerrar la app y no lo borra una actualización desde Supabase', () async {
      await _cache().agregarPendiente(_registro('pendiente-1'));
      await _cache().agregarPendiente(_registro('ya-subido'));
      await _cache().marcarSincronizado('ya-subido');

      // "Cerrar y abrir la app": se olvida lo cargado y se lee de nuevo el almacén.
      CacheSincronizable.reiniciar();
      expect((await _cache().pendientes()).map((r) => r.id), ['pendiente-1']);
      final leido = (await _cache().todos()).firstWhere((r) => r.id == 'pendiente-1');
      expect(leido.cloradaCloroResidual, 1.1);
      expect(leido.puntosControl.single.areaNombre, 'Biocabaña');
      expect(leido.createdAt, DateTime(2026, 11, 25, 7, 31));

      // Supabase responde sin el pendiente: se reemplaza lo sincronizado y se conserva lo pendiente.
      await _cache().reemplazarSincronizados([_registro('remoto-1')]);
      expect((await _cache().todos()).map((r) => r.id).toSet(), {'pendiente-1', 'remoto-1'});
      expect(await _cache().contarPendientes(), 1);
    });

    test('Jornada de medidores: conserva lecturas y la referencia a la foto local', () {
      final j = JornadaMedidores(
        id: generarUuid(),
        fecha: DateTime(2026, 11, 25),
        hora: '09:00',
        responsableLectura: 'Karol',
        consumoTotalMicros: 10,
        consumoMacromedidor: 12,
        aguaNoRegistrada: 2,
        lecturas: const [
          LecturaMedidor(
            medidorId: 1,
            medidorNombre: 'ENCC',
            tipoMedidor: 'micromedidor',
            lecturaActual: 100,
            lecturaAnterior: 98,
            consumo: 2,
            fotoUrl: 'local:/datos/foto.jpg',
          ),
        ],
        createdBy: 'karol',
        createdAt: DateTime(2026, 11, 25, 9),
      );
      final copia = SerializacionLocal.jornadaDeMapa(SerializacionLocal.jornadaAMapa(j));
      expect(copia.lecturas.single.medidorNombre, 'ENCC');
      expect(FotoLecturaService.rutaLocalDe(copia.lecturas.single.fotoUrl), '/datos/foto.jpg');
      expect(FotoLecturaService.rutaLocalDe('2026-11-25/abc/MIC-01.jpg'), isNull);
    });
  });

  group('Repositorios en modo local (sin Supabase)', () {
    test('DO-F-070: lo guardado sigue ahí al reabrir la app', () async {
      final id = generarUuid();
      await FisicoquimicoRepository().guardarRegistro(_registro(id));

      CacheSincronizable.reiniciar();
      final registros = await FisicoquimicoRepository().obtenerRegistros();
      final guardado = registros.firstWhere((r) => r.id == id);
      // Cada punto de control recibió su propio id para no duplicarse al subirlo.
      expect(guardado.puntosControl.single.id, isNotNull);
      // En modo local no hay nada "pendiente de subir".
      expect(await FisicoquimicoRepository().contarPendientes(), 0);
    });

    test('Medidores: la última jornada guardada auto-llena las lecturas anteriores', () async {
      final repo = MedidoresRepository();
      await repo.guardarJornada(JornadaMedidores(
        id: generarUuid(),
        fecha: DateTime(2030, 1, 1),
        hora: '08:00',
        responsableLectura: 'Karol',
        consumoTotalMicros: 1,
        consumoMacromedidor: 1,
        aguaNoRegistrada: 0,
        lecturas: const [
          LecturaMedidor(medidorId: 1, medidorNombre: 'ENCC', tipoMedidor: 'micromedidor', lecturaActual: 999.5, lecturaAnterior: 998, consumo: 1.5),
        ],
        createdBy: 'karol',
        createdAt: DateTime(2030, 1, 1, 8),
      ));
      final otra = MedidoresRepository();
      await otra.obtenerJornadas();
      expect(otra.obtenerUltimasLecturas()[1], 999.5);
    });
  });

  test('Alertas: se guardan en el celular y vuelven al abrir la app', () async {
    final a = AlertasProvider();
    await a.listo;
    a.agregarAlerta(titulo: 'Cloro bajo', descripcion: '', severidad: SeveridadAlerta.critica, parametroClave: 'cloro_clorada');
    a.marcarResuelta(a.todas.single.id, resueltaPor: 'Karol', nota: 'Ajustado');
    await Future<void>.delayed(Duration.zero);

    final reabierta = AlertasProvider();
    await reabierta.listo;
    final alerta = reabierta.todas.single;
    expect(alerta.titulo, 'Cloro bajo');
    expect(alerta.resueltaPor, 'Karol');
    expect(alerta.notaResolucion, 'Ajustado');
    expect(alerta.severidad, SeveridadAlerta.critica);
  });

  testWidgets('Aviso: en modo local indica que los datos quedan en el celular', (tester) async {
    final sync = SincronizacionProvider(
      fisico: FisicoquimicoProvider(),
      medidores: MedidoresProvider(),
      caudal: CaudalProvider(),
      automatico: false,
    );
    addTearDown(sync.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sync,
        child: const MaterialApp(home: Scaffold(body: AvisoSincronizacion())),
      ),
    );
    await tester.pumpAndSettle();
    expect(sync.modoLocal, isTrue);
    expect(find.text('Modo local: los registros se guardan solo en este celular.'), findsOneWidget);
    expect(find.byKey(const Key('aviso_pendientes')), findsNothing);
  });

  test('Almacén en memoria: listas y objetos', () async {
    final a = AlmacenMemoria();
    await a.guardarLista('x', [
      {'a': 1},
    ]);
    expect(await a.leerLista('x'), [
      {'a': 1},
    ]);
    await a.guardarObjeto('perfil', {'id': 'k'});
    expect((await a.leerObjeto('perfil'))!['id'], 'k');
    await a.guardarObjeto('perfil', null);
    expect(await a.leerObjeto('perfil'), isNull);
  });
}

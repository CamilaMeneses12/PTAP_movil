import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/models/item_historial_modelo.dart';
import 'package:planta_agua/data/repositories/historial_repository.dart';
import 'package:planta_agua/presentation/history/providers/historial_provider.dart';

void main() {
  group('Módulo de Historial y Filtros', () {
    late HistorialRepository repository;
    late HistorialProvider provider;

    setUp(() {
      repository = HistorialRepository();
      provider = HistorialProvider(repository: repository);
    });

    test('ItemHistorial model contiene campos y texto de tipo correcto', () {
      final item = ItemHistorial(
        id: 'test-1',
        tipo: TipoRegistroHistorial.fisicoquimico,
        fecha: DateTime(2026, 2, 17),
        hora: '08:00',
        titulo: 'Calidad del Agua DO-F-070',
        subtitulo: 'pH: 7.2 | Turb: 1.1 NTU',
        responsable: 'Carlos Gomez',
        tieneAlerta: false,
        objetoOriginal: 'objeto',
      );

      expect(item.id, 'test-1');
      expect(item.tipo, TipoRegistroHistorial.fisicoquimico);
      expect(item.tipoTexto, 'Fisicoquímico (DO-F-070)');
      expect(item.tieneAlerta, isFalse);
    });

    test('HistorialRepository unifica registros de fisicoquímicos, medidores y caudal en orden cronológico', () async {
      final items = await repository.obtenerHistorialCompleto();

      // Debe contener registros de los tres módulos
      expect(items.isNotEmpty, isTrue);
      expect(items.any((i) => i.tipo == TipoRegistroHistorial.fisicoquimico), isTrue);
      expect(items.any((i) => i.tipo == TipoRegistroHistorial.medidores), isTrue);
      expect(items.any((i) => i.tipo == TipoRegistroHistorial.caudal), isTrue);

      // Debe estar ordenado de más reciente a más antiguo
      for (int i = 0; i < items.length - 1; i++) {
        final actual = items[i];
        final siguiente = items[i + 1];
        expect(
          actual.fecha.isAfter(siguiente.fecha) || actual.fecha.isAtSameMomentAs(siguiente.fecha),
          isTrue,
        );
      }
    });

    test('HistorialRepository extrae lista de responsables únicos sin vacíos', () async {
      final usuarios = await repository.obtenerResponsablesUnicos();
      expect(usuarios.isNotEmpty, isTrue);
      for (final u in usuarios) {
        expect(u.trim().isNotEmpty, isTrue);
      }
    });

    test('HistorialProvider filtra por tipo de registro', () async {
      await provider.cargarHistorial();
      final totalInicial = provider.totalItems;
      expect(totalInicial, greaterThan(0));

      // Filtrar solo fisicoquímicos
      provider.setTipo(TipoRegistroHistorial.fisicoquimico);
      expect(provider.items.every((i) => i.tipo == TipoRegistroHistorial.fisicoquimico), isTrue);

      // Filtrar solo caudal
      provider.setTipo(TipoRegistroHistorial.caudal);
      expect(provider.items.every((i) => i.tipo == TipoRegistroHistorial.caudal), isTrue);

      // Filtrar solo medidores
      provider.setTipo(TipoRegistroHistorial.medidores);
      expect(provider.items.every((i) => i.tipo == TipoRegistroHistorial.medidores), isTrue);

      // Volver a todos
      provider.setTipo(TipoRegistroHistorial.todos);
      expect(provider.totalItems, equals(totalInicial));
    });

    test('HistorialProvider filtra por rango de fechas', () async {
      await provider.cargarHistorial();
      final inicio = DateTime(2026, 1, 1);
      final fin = DateTime(2026, 12, 31);

      provider.setRangoFechas(inicio, fin);

      for (final item in provider.items) {
        expect(item.fecha.isAfter(inicio) || item.fecha.isAtSameMomentAs(inicio), isTrue);
        expect(item.fecha.isBefore(DateTime(2026, 12, 31, 23, 59, 59)), isTrue);
      }
    });

    test('HistorialProvider filtra por usuario responsable', () async {
      await provider.cargarHistorial();
      final usuarios = provider.usuariosDisponibles;
      expect(usuarios.isNotEmpty, isTrue);

      final usuarioPrueba = usuarios.first;
      provider.setUsuario(usuarioPrueba);

      expect(provider.items.isNotEmpty, isTrue);
      for (final item in provider.items) {
        expect(item.responsable.toLowerCase(), contains(usuarioPrueba.toLowerCase()));
      }
    });

    test('HistorialProvider filtra solo registros con alertas', () async {
      await provider.cargarHistorial();
      provider.setSoloAlertas(true);

      for (final item in provider.items) {
        expect(item.tieneAlerta, isTrue);
      }
    });

    test('HistorialProvider filtra por búsqueda textual', () async {
      await provider.cargarHistorial();
      provider.setBusqueda('pH');

      expect(provider.items.isNotEmpty, isTrue);
      for (final item in provider.items) {
        final matchTitulo = item.titulo.toLowerCase().contains('ph');
        final matchSubtitulo = item.subtitulo.toLowerCase().contains('ph');
        final matchResponsable = item.responsable.toLowerCase().contains('ph');
        expect(matchTitulo || matchSubtitulo || matchResponsable, isTrue);
      }
    });

    test('HistorialProvider restablece filtros con limpiarFiltros', () async {
      await provider.cargarHistorial();
      final totalInicial = provider.totalItems;

      provider.setTipo(TipoRegistroHistorial.medidores);
      provider.setSoloAlertas(true);
      provider.setBusqueda('xyz');
      expect(provider.conteoFiltrosActivos, greaterThan(0));

      provider.limpiarFiltros();
      expect(provider.conteoFiltrosActivos, equals(0));
      expect(provider.tipoSeleccionado, equals(TipoRegistroHistorial.todos));
      expect(provider.fechaInicio, isNull);
      expect(provider.fechaFin, isNull);
      expect(provider.usuarioSeleccionado, isNull);
      expect(provider.soloAlertas, isFalse);
      expect(provider.busquedaTexto, isEmpty);
      expect(provider.totalItems, equals(totalInicial));
    });
  });
}

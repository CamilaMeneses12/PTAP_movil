import 'package:flutter/foundation.dart';
import '../../../data/models/alerta_sistema_modelo.dart';

class AlertasProvider with ChangeNotifier {
  final List<AlertaSistema> _alertas = [
    // Alertas activas HOY (fieles a Figma 05 Alertas)
    AlertaSistema(
      id: 'alt-01',
      titulo: 'Caudal de entrada fuera de rango',
      descripcion: 'Pico de 142,6 L/s a las 07:48. Máximo permitido: 140 L/s.',
      severidad: SeveridadAlerta.critica,
      fechaHora: DateTime.now().subtract(const Duration(minutes: 50)),
      hora: '07:48',
      parametro: 'Caudal de entrada',
      valorRegistrado: 142.6,
      rangoEsperado: '110–140 L/s',
      grupoFecha: 'HOY',
    ),
    AlertaSistema(
      id: 'alt-02',
      titulo: 'Nivel de tanque descendiendo',
      descripcion: 'Bajó 6% en la última hora. Nivel actual 78%; mínimo operativo 40%.',
      severidad: SeveridadAlerta.advertencia,
      fechaHora: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      hora: '08:24',
      parametro: 'Nivel de tanque',
      valorRegistrado: 78.0,
      rangoEsperado: 'mín. 40%',
      grupoFecha: 'HOY',
    ),
    AlertaSistema(
      id: 'alt-03',
      titulo: 'Posible anomalía de presión',
      descripcion: 'Variación de >0,6 bar en 10 min en la línea de impulsión.',
      severidad: SeveridadAlerta.advertencia,
      fechaHora: DateTime.now().subtract(const Duration(minutes: 25)),
      hora: '09:11',
      parametro: 'Presión de red',
      valorRegistrado: 3.4,
      rangoEsperado: '2,8–4,0 bar',
      grupoFecha: 'HOY',
    ),

    // Historial AYER (fieles a Figma 05 Alertas)
    AlertaSistema(
      id: 'alt-04',
      titulo: 'Retrolavado programado - Filtro 3',
      descripcion: 'Inicia hoy a las 09:00. Duración estimada: 45 min.',
      severidad: SeveridadAlerta.informacion,
      fechaHora: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      hora: '06:20',
      resuelta: true,
      leida: true,
      grupoFecha: 'AYER',
    ),
    AlertaSistema(
      id: 'alt-05',
      titulo: 'Calibración de caudalímetro',
      descripcion: 'Caudalímetro de salida calibrado. Error de medición ±0,1%.',
      severidad: SeveridadAlerta.informacion,
      fechaHora: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      hora: '04:15',
      resuelta: true,
      leida: true,
      grupoFecha: 'AYER',
    ),
  ];

  List<AlertaSistema> get todas => List.unmodifiable(_alertas);
  List<AlertaSistema> get activas => _alertas.where((a) => !a.resuelta).toList();
  List<AlertaSistema> get historial => _alertas.where((a) => a.resuelta).toList();

  int get activasCount => activas.length;
  int get criticasCount => activas.where((a) => a.severidad == SeveridadAlerta.critica).length;
  int get advertenciasCount => activas.where((a) => a.severidad == SeveridadAlerta.advertencia).length;
  int get informacionCount => activas.where((a) => a.severidad == SeveridadAlerta.informacion).length;

  int get noLeidasCount => _alertas.where((a) => !a.leida).length;

  void marcarTodasLeidas() {
    for (int i = 0; i < _alertas.length; i++) {
      _alertas[i] = _alertas[i].copyWith(leida: true);
    }
    notifyListeners();
  }

  void marcarResuelta(String id) {
    final idx = _alertas.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alertas[idx] = _alertas[idx].copyWith(resuelta: true, leida: true);
      notifyListeners();
    }
  }

  void agregarAlerta({
    required String titulo,
    required String descripcion,
    required SeveridadAlerta severidad,
    String? parametro,
    double? valorRegistrado,
    String? rangoEsperado,
  }) {
    final ahora = DateTime.now();
    final hora = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    _alertas.insert(
      0,
      AlertaSistema(
        id: 'alt-${DateTime.now().millisecondsSinceEpoch}',
        titulo: titulo,
        descripcion: descripcion,
        severidad: severidad,
        fechaHora: ahora,
        hora: hora,
        parametro: parametro,
        valorRegistrado: valorRegistrado,
        rangoEsperado: rangoEsperado,
        grupoFecha: 'HOY',
      ),
    );
    notifyListeners();
  }
}

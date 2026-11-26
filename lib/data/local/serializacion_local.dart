import '../models/aforo_caudal_modelo.dart';
import '../models/medidores_modelos.dart';
import '../models/registro_fisicoquimico.dart';

/// Conversión de los registros a JSON para guardarlos en el celular, sin perder lo anidado
/// (puntos de control, lecturas) ni la fecha de creación.
class SerializacionLocal {
  // --- DO-F-070 ---
  static Map<String, dynamic> fisicoquimicoAMapa(RegistroFisicoquimico r) => {
        ...r.toMap(),
        'created_at': r.createdAt.toIso8601String(),
        'puntos': [for (final p in r.puntosControl) p.toMap()],
      };

  static RegistroFisicoquimico fisicoquimicoDeMapa(Map<String, dynamic> m) => RegistroFisicoquimico.fromMap(
        m,
        puntos: [
          for (final p in (m['puntos'] as List? ?? const []))
            MedicionPuntoControl.fromMap(Map<String, dynamic>.from(p as Map)),
        ],
      );

  // --- Medidores ---
  static Map<String, dynamic> jornadaAMapa(JornadaMedidores j) => {
        ...j.toMap(),
        'created_at': j.createdAt.toIso8601String(),
        'lecturas': [
          for (final l in j.lecturas)
            {...l.toMap(), 'medidor_nombre': l.medidorNombre, 'tipo_medidor': l.tipoMedidor},
        ],
      };

  static JornadaMedidores jornadaDeMapa(Map<String, dynamic> m) => JornadaMedidores.fromMap(
        m,
        lecturas: [
          for (final l in (m['lecturas'] as List? ?? const []))
            LecturaMedidor.fromMap(Map<String, dynamic>.from(l as Map)),
        ],
      );

  // --- Aforos ---
  static Map<String, dynamic> aforoAMapa(AforoCaudal a) => {
        ...a.toMap(),
        'created_at': a.createdAt.toIso8601String(),
      };

  static AforoCaudal aforoDeMapa(Map<String, dynamic> m) => AforoCaudal.fromMap(m);
}

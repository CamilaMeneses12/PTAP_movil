/// Modelo que representa el perfil del usuario autenticado y su rol en la PTAP
class UsuarioPerfil {
  final String id;
  final String nombreCompleto;
  final String correo;
  final String rol; // 'operario', 'administrador', 'consultor_siga'
  final bool activo;
  final DateTime createdAt;

  const UsuarioPerfil({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.createdAt,
  });

  bool get esOperario => rol == 'operario';
  bool get esAdministrador => rol == 'administrador';
  bool get esConsultorSiga => rol == 'consultor_siga';

  /// Nombre oficial de la planta
  String get plantaNombre => 'PTAP Villa Clara';

  /// Permite crear o editar registros operativos
  bool get puedeEditar => esOperario || esAdministrador;

  /// Permite gestionar catálogos y usuarios
  bool get puedeAdministrar => esAdministrador;

  factory UsuarioPerfil.fromMap(Map<String, dynamic> map) {
    return UsuarioPerfil(
      id: map['id'] as String,
      nombreCompleto: (map['nombre_completo'] as String?) ?? '',
      correo: (map['correo'] as String?) ?? '',
      rol: (map['rol'] as String?) ?? 'operario',
      activo: (map['activo'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'correo': correo,
      'rol': rol,
      'activo': activo,
    };
  }

  UsuarioPerfil copyWith({
    String? id,
    String? nombreCompleto,
    String? correo,
    String? rol,
    bool? activo,
    DateTime? createdAt,
  }) {
    return UsuarioPerfil(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

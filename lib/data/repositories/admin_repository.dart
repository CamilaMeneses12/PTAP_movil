import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/supabase_config.dart';
import '../models/medidores_modelos.dart';
import '../models/parametro_catalogo_modelo.dart';
import '../models/usuario_perfil.dart';
import 'medidores_repository.dart';

/// Repositorio para la gestión administrativa de usuarios, medidores y parámetros
class AdminRepository {
  final SupabaseClient? _supabase;

  AdminRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? (SupabaseConfig.estaInicializado ? SupabaseConfig.cliente : null);

  // Semilla de usuarios del sistema
  static final List<UsuarioPerfil> _usuariosMemoria = [
    UsuarioPerfil(
      id: 'admin-01',
      nombreCompleto: 'Diego Calderón (Administrador PTAP)',
      correo: 'admin.ptap@sena.edu.co',
      rol: 'administrador',
      activo: true,
      createdAt: DateTime(2025, 1, 15),
    ),
    UsuarioPerfil(
      id: 'operario-01',
      nombreCompleto: 'Carlos Gómez (Operario de Turno)',
      correo: 'operario.ptap@sena.edu.co',
      rol: 'operario',
      activo: true,
      createdAt: DateTime(2025, 2, 1),
    ),
    UsuarioPerfil(
      id: 'siga-01',
      nombreCompleto: 'Auditor SIGA La Salada',
      correo: 'auditoria.siga@sena.edu.co',
      rol: 'consultor_siga',
      activo: true,
      createdAt: DateTime(2025, 3, 10),
    ),
  ];

  // Catálogo inicial de medidores (los 9 oficiales del formato)
  static final List<Medidor> _medidoresMemoria = List.from(MedidoresRepository.medidoresOficiales);

  // Catálogo inicial de parámetros y rangos según Resolución 2115 de 2007
  static final List<ParametroCatalogo> _parametrosMemoria = [
    const ParametroCatalogo(
      id: 'param-ph-clorada',
      codigo: 'PH_TRATADA',
      nombre: 'pH Agua Tratada',
      unidad: 'Unidades pH',
      valorMin: 6.5,
      valorMax: 9.0,
      puntoEtapa: 'agua_clorada',
      normaReferencia: 'Resolución 2115 de 2007 (Art. 7)',
    ),
    const ParametroCatalogo(
      id: 'param-cloro-clorada',
      codigo: 'CLORO_RESIDUAL',
      nombre: 'Cloro Residual Libre',
      unidad: 'mg/L',
      valorMin: 0.3,
      valorMax: 2.0,
      puntoEtapa: 'agua_clorada',
      normaReferencia: 'Resolución 2115 de 2007 (Art. 8)',
    ),
    const ParametroCatalogo(
      id: 'param-turb-clorada',
      codigo: 'TURB_TRATADA',
      nombre: 'Turbidez Agua Tratada',
      unidad: 'UNT',
      valorMin: 0.0,
      valorMax: 2.0,
      puntoEtapa: 'agua_clorada',
      normaReferencia: 'Resolución 2115 de 2007 (Art. 7)',
    ),
    const ParametroCatalogo(
      id: 'param-color-clorada',
      codigo: 'COLOR_TRATADA',
      nombre: 'Color Aparente Agua Tratada',
      unidad: 'UPC',
      valorMin: 0.0,
      valorMax: 15.0,
      puntoEtapa: 'agua_clorada',
      normaReferencia: 'Resolución 2115 de 2007 (Art. 7)',
    ),
    const ParametroCatalogo(
      id: 'param-turb-filtrada',
      codigo: 'TURB_FILTRADA',
      nombre: 'Turbidez Agua Filtrada',
      unidad: 'UNT',
      valorMin: 0.0,
      valorMax: 2.0,
      puntoEtapa: 'agua_filtrada',
      normaReferencia: 'Control Operativo PTAP',
    ),
    const ParametroCatalogo(
      id: 'param-ph-cruda',
      codigo: 'PH_CRUDA',
      nombre: 'pH Agua Cruda',
      unidad: 'Unidades pH',
      valorMin: 5.0,
      valorMax: 9.0,
      puntoEtapa: 'agua_cruda',
      normaReferencia: 'Control de Captación',
    ),
    const ParametroCatalogo(
      id: 'param-turb-cruda',
      codigo: 'TURB_CRUDA',
      nombre: 'Turbidez Agua Cruda',
      unidad: 'UJT',
      valorMin: 0.0,
      valorMax: 10.0,
      puntoEtapa: 'agua_cruda',
      normaReferencia: 'Control de Captación',
    ),
    const ParametroCatalogo(
      id: 'param-color-cruda',
      codigo: 'COLOR_CRUDA',
      nombre: 'Color Agua Cruda',
      unidad: 'UPC',
      valorMin: 0.0,
      valorMax: 20.0,
      puntoEtapa: 'agua_cruda',
      normaReferencia: 'Control de Captación',
    ),
  ];

  // ---------------------------------------------------------------------------
  // GESTIÓN DE USUARIOS
  // ---------------------------------------------------------------------------
  Future<List<UsuarioPerfil>> obtenerUsuarios() async {
    if (_supabase != null) {
      try {
        final res = await _supabase.from('perfiles').select().order('created_at', ascending: true);
        final lista = (res as List).map((m) => UsuarioPerfil.fromMap(m)).toList();
        if (lista.isNotEmpty) return lista;
      } catch (_) {}
    }
    return List.from(_usuariosMemoria);
  }

  /// Registra un nuevo usuario en la lista de memoria del sistema
  static void registrarUsuario(UsuarioPerfil usuario) {
    final idx = _usuariosMemoria.indexWhere(
      (u) => u.correo.trim().toLowerCase() == usuario.correo.trim().toLowerCase(),
    );
    if (idx == -1) {
      _usuariosMemoria.add(usuario);
    } else {
      _usuariosMemoria[idx] = usuario;
    }
  }

  /// Busca un usuario por correo electrónico
  static UsuarioPerfil? buscarPorCorreo(String correo) {
    final emailNorm = correo.trim().toLowerCase();
    try {
      return _usuariosMemoria.firstWhere(
        (u) => u.correo.trim().toLowerCase() == emailNorm,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> actualizarRolUsuario(String usuarioId, String nuevoRol) async {
    final idx = _usuariosMemoria.indexWhere((u) => u.id == usuarioId);
    if (idx != -1) {
      _usuariosMemoria[idx] = _usuariosMemoria[idx].copyWith(rol: nuevoRol);
    }

    if (_supabase != null) {
      try {
        await _supabase.from('perfiles').update({'rol': nuevoRol}).eq('id', usuarioId);
      } catch (_) {}
    }
  }

  Future<void> actualizarEstadoUsuario(String usuarioId, bool activo) async {
    final idx = _usuariosMemoria.indexWhere((u) => u.id == usuarioId);
    if (idx != -1) {
      _usuariosMemoria[idx] = _usuariosMemoria[idx].copyWith(activo: activo);
    }

    if (_supabase != null) {
      try {
        await _supabase.from('perfiles').update({'activo': activo}).eq('id', usuarioId);
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE CATÁLOGO DE MEDIDORES
  // ---------------------------------------------------------------------------
  Future<List<Medidor>> obtenerCatalogoMedidores() async {
    return List.from(_medidoresMemoria);
  }

  Future<void> actualizarEstadoMedidor(int medidorId, bool activo) async {
    final idx = _medidoresMemoria.indexWhere((m) => m.id == medidorId);
    if (idx != -1) {
      _medidoresMemoria[idx] = _medidoresMemoria[idx].copyWith(activo: activo);
    }
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE CATÁLOGO DE PARÁMETROS
  // ---------------------------------------------------------------------------
  Future<List<ParametroCatalogo>> obtenerCatalogoParametros() async {
    return List.from(_parametrosMemoria);
  }

  Future<void> actualizarRangoParametro(String parametroId, double min, double max) async {
    final idx = _parametrosMemoria.indexWhere((p) => p.id == parametroId);
    if (idx != -1) {
      _parametrosMemoria[idx] = _parametrosMemoria[idx].copyWith(
        valorMin: min,
        valorMax: max,
      );
    }
  }
}

import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Representa un perfil de usuario almacenado en la tabla `profiles`
/// de Supabase. Se crea automáticamente mediante el trigger
/// `trg_on_auth_user_created` / función `handle_new_user()` apenas se
/// registra un usuario en Supabase Auth — la app NUNCA debe insertar
/// manualmente en `profiles` al registrar, solo leerlo después.
class UserProfileModel extends Equatable {
  final String id;
  final String email;
  final String? nombreCompleto;
  final String? nombreUsuario;
  final String? avatarUrl;
  final String rol; // 'admin' | 'moderador' | 'usuario'
  final DateTime? fechaNacimiento;
  final int creditos;
  final DateTime creadoEn;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.rol,
    required this.creadoEn,
    this.nombreCompleto,
    this.nombreUsuario,
    this.avatarUrl,
    this.fechaNacimiento,
    this.creditos = 0,
  });

  /// Indica si el usuario tiene privilegios de administrador.
  bool get isAdmin => rol == AppConstants.roleAdmin;

  /// Indica si el usuario es moderador (puede eliminar cualquier
  /// comentario de libro y moderar el Foro de Poemas, pero no tiene
  /// el resto de permisos de administrador).
  bool get isModerador => rol == AppConstants.roleModerador;

  /// Verdadero para admin o moderador (permisos de moderación).
  bool get canModerate => isAdmin || isModerador;

  /// Nombre para mostrar en saludos y encabezados: usa el nombre
  /// completo si existe, o el correo como respaldo.
  String get displayName =>
      (nombreCompleto != null && nombreCompleto!.trim().isNotEmpty)
          ? nombreCompleto!
          : email;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String?,
      nombreUsuario: json['nombre_usuario'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      rol: json['rol'] as String? ?? AppConstants.roleUsuario,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'] as String)
          : null,
      creditos: json['creditos'] as int? ?? 0,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  /// Solo los campos editables por el propio usuario (ver política
  /// `profiles_update_propio`); nunca incluye `rol`, protegido además
  /// a nivel de base de datos por el trigger `proteger_cambio_rol`.
  Map<String, dynamic> toUpdateJson() {
    return {
      'nombre_completo': nombreCompleto,
      'nombre_usuario': nombreUsuario,
      'avatar_url': avatarUrl,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? nombreCompleto,
    String? nombreUsuario,
    String? avatarUrl,
    DateTime? fechaNacimiento,
    String? rol,
    int? creditos,
  }) {
    return UserProfileModel(
      id: id,
      email: email,
      rol: rol ?? this.rol,
      creadoEn: creadoEn,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      creditos: creditos ?? this.creditos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        nombreCompleto,
        nombreUsuario,
        avatarUrl,
        rol,
        fechaNacimiento,
        creditos,
        creadoEn,
      ];
}

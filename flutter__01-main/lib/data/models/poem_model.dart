import 'package:equatable/equatable.dart';

/// Representa un poema del Foro de Poemas, leído desde la vista
/// `poemas_con_estadisticas` (tabla real `poems` + agregados de
/// `poem_likes` y `poem_ratings` ya calculados en el servidor).
class PoemModel extends Equatable {
  final String id;
  final String usuarioId;
  final String titulo;
  final String contenido;
  final String nombreAutor;
  final int totalLikes;
  final int totalCalificaciones;
  final double promedioEstrellas;
  final DateTime creadoEn;

  const PoemModel({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.contenido,
    required this.nombreAutor,
    required this.totalLikes,
    required this.totalCalificaciones,
    required this.promedioEstrellas,
    required this.creadoEn,
  });

  factory PoemModel.fromJson(Map<String, dynamic> json) {
    return PoemModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      titulo: json['titulo'] as String,
      contenido: json['contenido'] as String,
      nombreAutor: json['nombre_autor'] as String,
      totalLikes: json['total_likes'] as int? ?? 0,
      totalCalificaciones: json['total_calificaciones'] as int? ?? 0,
      promedioEstrellas:
          (json['promedio_estrellas'] as num?)?.toDouble() ?? 0,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        usuarioId,
        titulo,
        contenido,
        nombreAutor,
        totalLikes,
        totalCalificaciones,
        promedioEstrellas,
        creadoEn,
      ];
}

/// Estadísticas agregadas de un usuario en el Foro de Poemas, leídas
/// desde la vista `estadisticas_poemas_usuario`.
class PoemUserStatsModel extends Equatable {
  final int totalPoemas;
  final int totalLikesRecibidos;
  final double promedioCalificacion;

  const PoemUserStatsModel({
    required this.totalPoemas,
    required this.totalLikesRecibidos,
    required this.promedioCalificacion,
  });

  factory PoemUserStatsModel.empty() => const PoemUserStatsModel(
        totalPoemas: 0,
        totalLikesRecibidos: 0,
        promedioCalificacion: 0,
      );

  factory PoemUserStatsModel.fromJson(Map<String, dynamic> json) {
    return PoemUserStatsModel(
      totalPoemas: json['total_poemas'] as int? ?? 0,
      totalLikesRecibidos: json['total_likes_recibidos'] as int? ?? 0,
      promedioCalificacion:
          (json['promedio_calificacion'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [totalPoemas, totalLikesRecibidos, promedioCalificacion];
}

/// Reporte de un poema (tabla `poem_reports`), visible solo para
/// admin/moderador.
class PoemReportModel extends Equatable {
  final String id;
  final String poemaId;
  final String usuarioId;
  final String motivo;
  final DateTime creadoEn;

  const PoemReportModel({
    required this.id,
    required this.poemaId,
    required this.usuarioId,
    required this.motivo,
    required this.creadoEn,
  });

  factory PoemReportModel.fromJson(Map<String, dynamic> json) {
    return PoemReportModel(
      id: json['id'] as String,
      poemaId: json['poema_id'] as String,
      usuarioId: json['usuario_id'] as String,
      motivo: json['motivo'] as String,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, poemaId, usuarioId, motivo, creadoEn];
}

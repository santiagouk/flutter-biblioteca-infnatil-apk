import 'package:equatable/equatable.dart';

/// Representa un comentario sobre un libro (tabla `book_comments`),
/// mostrado en la sección "¿Qué te pareció este libro?" del detalle.
class BookCommentModel extends Equatable {
  final String id;
  final String usuarioId;
  final String libroId;
  final String nombreMostrado;
  final String comentario;
  final DateTime creadoEn;

  const BookCommentModel({
    required this.id,
    required this.usuarioId,
    required this.libroId,
    required this.nombreMostrado,
    required this.comentario,
    required this.creadoEn,
  });

  factory BookCommentModel.fromJson(Map<String, dynamic> json) {
    return BookCommentModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      libroId: json['libro_id'] as String,
      nombreMostrado: json['nombre_mostrado'] as String,
      comentario: json['comentario'] as String,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, usuarioId, libroId, nombreMostrado, comentario, creadoEn];
}

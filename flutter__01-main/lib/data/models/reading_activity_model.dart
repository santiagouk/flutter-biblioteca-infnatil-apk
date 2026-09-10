import 'package:equatable/equatable.dart';
import 'book_model.dart';

/// Representa una fila de la tabla `favorites`: la relación entre un
/// usuario y un libro marcado como favorito.
class FavoriteModel extends Equatable {
  final String id;
  final String usuarioId;
  final String libroId;
  final DateTime creadoEn;

  const FavoriteModel({
    required this.id,
    required this.usuarioId,
    required this.libroId,
    required this.creadoEn,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      libroId: json['libro_id'] as String,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, usuarioId, libroId, creadoEn];
}

/// Combina un [ReadingHistoryModel] con el [BookModel] correspondiente,
/// listo para mostrarse directamente en la pantalla de Historial.
class ReadingHistoryEntry {
  final ReadingHistoryModel history;
  final BookModel book;

  const ReadingHistoryEntry({required this.history, required this.book});
}

/// Representa una fila de la tabla `reading_history`: el registro de
/// que un usuario leyó (o continúa leyendo) un libro, junto con su
/// progreso (página actual, porcentaje completado y si ya terminó).
///
/// `ultima_lectura` se actualiza automáticamente en cada UPDATE
/// mediante el trigger `trg_reading_history_actualizado` /
/// `actualizar_ultima_lectura()`, por lo que la app no necesita
/// enviarlo explícitamente al guardar progreso.
class ReadingHistoryModel extends Equatable {
  final String id;
  final String usuarioId;
  final String libroId;
  final int ultimaPagina;
  final double porcentajeCompletado;
  final bool completado;
  final DateTime primeraLectura;
  final DateTime ultimaLectura;

  const ReadingHistoryModel({
    required this.id,
    required this.usuarioId,
    required this.libroId,
    required this.ultimaPagina,
    required this.porcentajeCompletado,
    required this.completado,
    required this.primeraLectura,
    required this.ultimaLectura,
  });

  factory ReadingHistoryModel.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      libroId: json['libro_id'] as String,
      ultimaPagina: json['ultima_pagina'] as int? ?? 1,
      porcentajeCompletado:
          (json['porcentaje_completado'] as num?)?.toDouble() ?? 0,
      completado: json['completado'] as bool? ?? false,
      primeraLectura: json['primera_lectura'] != null
          ? DateTime.parse(json['primera_lectura'] as String)
          : DateTime.now(),
      ultimaLectura: json['ultima_lectura'] != null
          ? DateTime.parse(json['ultima_lectura'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        usuarioId,
        libroId,
        ultimaPagina,
        porcentajeCompletado,
        completado,
        primeraLectura,
        ultimaLectura,
      ];
}

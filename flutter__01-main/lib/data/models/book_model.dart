import 'package:equatable/equatable.dart';

/// Representa un libro almacenado en la tabla `books` de Supabase.
///
/// [portadaUrl] y [archivoPdfUrl] apuntan a objetos públicos dentro de
/// los buckets de Supabase Storage `portadas` y `libros-pdf`
/// respectivamente. El catálogo real solo maneja PDF (no hay soporte
/// de EPUB en el esquema actual).
class BookModel extends Equatable {
  final String id;
  final String titulo;
  final String autor;
  final String? descripcion;
  final String? sinopsis;
  final String? categoriaId;
  final String edadRecomendada; // '3-5' | '6-8' | '9-12' | '13+'
  final String idioma;
  final String? portadaUrl;
  final String archivoPdfUrl;
  final int? numeroPaginas;
  final bool destacado;
  final bool publicado;
  final String? fuenteDominioPublico;
  final int? anioPublicacionOriginal;
  final bool esVip;
  final int costoCreditos;
  final DateTime creadoEn;

  const BookModel({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.edadRecomendada,
    required this.idioma,
    required this.archivoPdfUrl,
    required this.destacado,
    required this.publicado,
    required this.creadoEn,
    this.descripcion,
    this.sinopsis,
    this.categoriaId,
    this.portadaUrl,
    this.numeroPaginas,
    this.fuenteDominioPublico,
    this.anioPublicacionOriginal,
    this.esVip = false,
    this.costoCreditos = 0,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      autor: json['autor'] as String,
      descripcion: json['descripcion'] as String?,
      sinopsis: json['sinopsis'] as String?,
      categoriaId: json['categoria_id'] as String?,
      edadRecomendada: json['edad_recomendada'] as String? ?? '6-8',
      idioma: json['idioma'] as String? ?? 'es',
      portadaUrl: json['portada_url'] as String?,
      archivoPdfUrl: json['archivo_pdf_url'] as String? ?? '',
      numeroPaginas: json['numero_paginas'] as int?,
      destacado: json['destacado'] as bool? ?? false,
      publicado: json['publicado'] as bool? ?? true,
      fuenteDominioPublico: json['fuente_dominio_publico'] as String?,
      anioPublicacionOriginal: json['anio_publicacion_original'] as int?,
      esVip: json['es_vip'] as bool? ?? false,
      costoCreditos: json['costo_creditos'] as int? ?? 0,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  /// Payload para crear/actualizar un libro desde el panel de
  /// administrador. No incluye `id` ni columnas gestionadas por la
  /// base de datos (`creado_por`, `creado_en`, `actualizado_en`).
  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'autor': autor,
      'descripcion': descripcion,
      'sinopsis': sinopsis,
      'categoria_id': categoriaId,
      'edad_recomendada': edadRecomendada,
      'idioma': idioma,
      'portada_url': portadaUrl,
      'archivo_pdf_url': archivoPdfUrl,
      'numero_paginas': numeroPaginas,
      'destacado': destacado,
      'publicado': publicado,
      'fuente_dominio_publico': fuenteDominioPublico,
      'anio_publicacion_original': anioPublicacionOriginal,
      'es_vip': esVip,
      'costo_creditos': costoCreditos,
    };
  }

  BookModel copyWith({
    String? titulo,
    String? autor,
    String? descripcion,
    String? sinopsis,
    String? categoriaId,
    String? edadRecomendada,
    String? idioma,
    String? portadaUrl,
    String? archivoPdfUrl,
    int? numeroPaginas,
    bool? destacado,
    bool? publicado,
    String? fuenteDominioPublico,
    int? anioPublicacionOriginal,
    bool? esVip,
    int? costoCreditos,
  }) {
    return BookModel(
      id: id,
      titulo: titulo ?? this.titulo,
      autor: autor ?? this.autor,
      descripcion: descripcion ?? this.descripcion,
      sinopsis: sinopsis ?? this.sinopsis,
      categoriaId: categoriaId ?? this.categoriaId,
      edadRecomendada: edadRecomendada ?? this.edadRecomendada,
      idioma: idioma ?? this.idioma,
      portadaUrl: portadaUrl ?? this.portadaUrl,
      archivoPdfUrl: archivoPdfUrl ?? this.archivoPdfUrl,
      numeroPaginas: numeroPaginas ?? this.numeroPaginas,
      destacado: destacado ?? this.destacado,
      publicado: publicado ?? this.publicado,
      fuenteDominioPublico:
          fuenteDominioPublico ?? this.fuenteDominioPublico,
      anioPublicacionOriginal:
          anioPublicacionOriginal ?? this.anioPublicacionOriginal,
      esVip: esVip ?? this.esVip,
      costoCreditos: costoCreditos ?? this.costoCreditos,
      creadoEn: creadoEn,
    );
  }

  @override
  List<Object?> get props => [
        id,
        titulo,
        autor,
        descripcion,
        sinopsis,
        categoriaId,
        edadRecomendada,
        idioma,
        portadaUrl,
        archivoPdfUrl,
        numeroPaginas,
        destacado,
        publicado,
        fuenteDominioPublico,
        anioPublicacionOriginal,
        esVip,
        costoCreditos,
        creadoEn,
      ];
}

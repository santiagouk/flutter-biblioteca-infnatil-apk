import 'package:equatable/equatable.dart';

/// Representa una categoría infantil (tabla `categories` en Supabase).
///
/// Ejemplos reales: Aventura, Fantasía, Animales, Ciencia, Valores,
/// Cuentos clásicos, etc. (13 categorías ya cargadas en producción).
class CategoryModel extends Equatable {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? icono; // Nombre lógico de icono (ver CategoryIcons)
  final String colorHex; // Color en formato "#RRGGBB", ej. "#6366f1"

  const CategoryModel({
    required this.id,
    required this.nombre,
    required this.colorHex,
    this.descripcion,
    this.icono,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      colorHex: json['color'] as String? ?? '#6366f1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': colorHex,
    };
  }

  CategoryModel copyWith({
    String? nombre,
    String? descripcion,
    String? icono,
    String? colorHex,
  }) {
    return CategoryModel(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [id, nombre, descripcion, icono, colorHex];
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/book_model.dart';
import 'supabase_client_service.dart';

/// Servicio de acceso a datos para la tabla `books`.
///
/// Reúne todas las consultas relacionadas con libros: catálogo
/// completo, destacados/recomendados, búsqueda por texto, filtrado
/// por categoría y las operaciones de creación/edición/eliminación
/// usadas por el panel de administrador.
///
/// Nota sobre visibilidad: la política `books_select_publicados`
/// limita la lectura de usuarios normales a libros con
/// `publicado = true`; los administradores además pueden ver todos
/// (`books_select_admin`, vía `es_admin()`). No es necesario repetir
/// ese filtro manualmente en cada consulta, pero se deja explícito
/// donde aporta claridad.
class BookService {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<BookModel>> fetchAll() async {
    try {
      final data = await _client
          .from(AppConstants.tableBooks)
          .select()
          .order('creado_en', ascending: false);
      return _mapList(data);
    } catch (e) {
      throw AppException('No fue posible cargar los libros: $e');
    }
  }

  /// Libros recomendados para la pantalla de Inicio, usando la misma
  /// función SQL que ya usa la versión web
  /// (`obtener_libros_recomendados`): prioriza popularidad real
  /// (me gusta + lecturas + favoritos) y usa destacados manuales como
  /// respaldo cuando aún no hay suficiente actividad.
  Future<List<BookModel>> fetchFeatured() async {
    try {
      final data = await _client.rpc(
        AppConstants.rpcLibrosRecomendados,
        params: {'limite': AppConstants.featuredBooksLimit},
      );
      return _mapList(data);
    } catch (e) {
      throw AppException('No fue posible cargar los libros destacados: $e');
    }
  }

  Future<List<BookModel>> fetchByCategory(String categoryId) async {
    try {
      final data = await _client
          .from(AppConstants.tableBooks)
          .select()
          .eq('categoria_id', categoryId);
      return _mapList(data);
    } catch (e) {
      throw AppException('No fue posible cargar los libros de la categoría: $e');
    }
  }

  /// Busca libros cuyo título o autor contenga [query] (insensible a
  /// mayúsculas), usando el operador `ilike` de PostgreSQL.
  Future<List<BookModel>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final pattern = '%${query.trim()}%';
      final data = await _client
          .from(AppConstants.tableBooks)
          .select()
          .or('titulo.ilike.$pattern,autor.ilike.$pattern');
      return _mapList(data);
    } catch (e) {
      throw AppException('No fue posible completar la búsqueda: $e');
    }
  }

  Future<BookModel> fetchById(String bookId) async {
    try {
      final data = await _client
          .from(AppConstants.tableBooks)
          .select()
          .eq('id', bookId)
          .single();
      return BookModel.fromJson(data);
    } catch (e) {
      throw AppException('No fue posible cargar el libro: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Operaciones de administrador (requieren `rol = 'admin'`, exigido
  // por las políticas `books_insert_admin` / `_update_admin` / `_delete_admin`)
  // ---------------------------------------------------------------------

  Future<BookModel> create(BookModel book) async {
    try {
      final data = await _client
          .from(AppConstants.tableBooks)
          .insert(book.toJson())
          .select()
          .single();
      return BookModel.fromJson(data);
    } catch (e) {
      throw AppException('No fue posible agregar el libro: $e');
    }
  }

  Future<void> update(BookModel book) async {
    try {
      await _client
          .from(AppConstants.tableBooks)
          .update(book.toJson())
          .eq('id', book.id);
    } catch (e) {
      throw AppException('No fue posible actualizar el libro: $e');
    }
  }

  Future<void> delete(String bookId) async {
    try {
      await _client.from(AppConstants.tableBooks).delete().eq('id', bookId);
    } catch (e) {
      throw AppException('No fue posible eliminar el libro: $e');
    }
  }

  /// Cantidad total de libros — usado en el panel de estadísticas.
  Future<int> countAll() async {
    try {
      final data = await _client.from(AppConstants.tableBooks).select('id');
      return (data as List).length;
    } catch (e) {
      throw AppException('No fue posible calcular las estadísticas: $e');
    }
  }

  List<BookModel> _mapList(dynamic data) {
    return (data as List)
        .map((row) => BookModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

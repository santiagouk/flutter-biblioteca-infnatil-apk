import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/book_comment_model.dart';
import 'supabase_client_service.dart';

/// Servicio de acceso a datos para `book_likes` y `book_comments`,
/// la sección "¿Qué te pareció este libro?" que ya existe en la
/// versión web.
class BookSocialService {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<int> fetchLikeCount(String bookId) async {
    try {
      final data = await _client
          .from(AppConstants.tableBookLikes)
          .select('id')
          .eq('libro_id', bookId);
      return (data as List).length;
    } catch (e) {
      throw AppException('No fue posible cargar los me gusta: $e');
    }
  }

  Future<bool> hasLiked({required String userId, required String bookId}) async {
    try {
      final data = await _client
          .from(AppConstants.tableBookLikes)
          .select('id')
          .eq('usuario_id', userId)
          .eq('libro_id', bookId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      throw AppException('No fue posible verificar tu me gusta: $e');
    }
  }

  /// Alterna el "me gusta" del usuario sobre el libro y devuelve el
  /// nuevo estado (`true` = ahora le gusta).
  Future<bool> toggleLike({required String userId, required String bookId}) async {
    final already = await hasLiked(userId: userId, bookId: bookId);
    try {
      if (already) {
        await _client
            .from(AppConstants.tableBookLikes)
            .delete()
            .eq('usuario_id', userId)
            .eq('libro_id', bookId);
        return false;
      }
      await _client.from(AppConstants.tableBookLikes).insert({
        'usuario_id': userId,
        'libro_id': bookId,
      });
      return true;
    } catch (e) {
      throw AppException('No fue posible actualizar tu me gusta: $e');
    }
  }

  Future<List<BookCommentModel>> fetchComments(String bookId) async {
    try {
      final data = await _client
          .from(AppConstants.tableBookComments)
          .select()
          .eq('libro_id', bookId)
          .order('creado_en', ascending: false);
      return (data as List)
          .map((row) => BookCommentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar los comentarios: $e');
    }
  }

  Future<BookCommentModel> addComment({
    required String userId,
    required String bookId,
    required String nombreMostrado,
    required String comentario,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.tableBookComments)
          .insert({
            'usuario_id': userId,
            'libro_id': bookId,
            'nombre_mostrado': nombreMostrado,
            'comentario': comentario,
          })
          .select()
          .single();
      return BookCommentModel.fromJson(data);
    } catch (e) {
      throw AppException('No fue posible publicar tu comentario: $e');
    }
  }

  /// Elimina un comentario. Las políticas RLS ya permiten esto al
  /// autor del comentario, a un moderador o a un admin — no hace
  /// falta duplicar esa comprobación aquí.
  Future<void> deleteComment(String commentId) async {
    try {
      await _client
          .from(AppConstants.tableBookComments)
          .delete()
          .eq('id', commentId);
    } catch (e) {
      throw AppException('No fue posible eliminar el comentario: $e');
    }
  }
}

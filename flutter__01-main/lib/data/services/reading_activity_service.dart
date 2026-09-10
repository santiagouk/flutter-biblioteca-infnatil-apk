import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/book_model.dart';
import '../models/reading_activity_model.dart';
import 'supabase_client_service.dart';

/// Servicio de acceso a datos para `favorites` y `reading_history`.
///
/// Encapsula tanto la lectura de las listas del usuario como las
/// acciones de marcar/desmarcar favorito y registrar el progreso de
/// lectura, uniendo siempre con la tabla `books` para devolver
/// directamente los [BookModel] listos para mostrar en pantalla.
class ReadingActivityService {
  final SupabaseClient _client = SupabaseClientService.client;

  // ---------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------

  Future<List<BookModel>> fetchFavoriteBooks(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.tableFavorites)
          .select('libro_id, books(*)')
          .eq('usuario_id', userId)
          .order('creado_en', ascending: false);

      return (data as List)
          .where((row) => row['books'] != null)
          .map((row) =>
              BookModel.fromJson(row['books'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar tus favoritos: $e');
    }
  }

  Future<bool> isFavorite(String userId, String bookId) async {
    try {
      final data = await _client
          .from(AppConstants.tableFavorites)
          .select('id')
          .eq('usuario_id', userId)
          .eq('libro_id', bookId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      throw AppException('No fue posible verificar el estado de favorito: $e');
    }
  }

  /// Alterna el estado de favorito de un libro y devuelve el nuevo
  /// estado resultante (`true` = ahora es favorito).
  Future<bool> toggleFavorite(String userId, String bookId) async {
    final alreadyFavorite = await isFavorite(userId, bookId);
    try {
      if (alreadyFavorite) {
        await _client
            .from(AppConstants.tableFavorites)
            .delete()
            .eq('usuario_id', userId)
            .eq('libro_id', bookId);
        return false;
      } else {
        await _client.from(AppConstants.tableFavorites).insert({
          'usuario_id': userId,
          'libro_id': bookId,
        });
        return true;
      }
    } catch (e) {
      throw AppException('No fue posible actualizar tus favoritos: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Historial de lectura
  // ---------------------------------------------------------------------

  Future<List<ReadingHistoryModel>> fetchHistory(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.tableReadingHistory)
          .select()
          .eq('usuario_id', userId)
          .order('ultima_lectura', ascending: false);
      return (data as List)
          .map((row) =>
              ReadingHistoryModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar tu historial de lectura: $e');
    }
  }

  /// Igual que [fetchHistory], pero además trae el [BookModel] de cada
  /// entrada (mediante un join con `books`) para que la pantalla de
  /// historial pueda mostrar portada y título sin peticiones extra.
  Future<List<ReadingHistoryEntry>> fetchHistoryEntries(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.tableReadingHistory)
          .select('*, books(*)')
          .eq('usuario_id', userId)
          .order('ultima_lectura', ascending: false);

      return (data as List)
          .where((row) => row['books'] != null)
          .map((row) => ReadingHistoryEntry(
                history: ReadingHistoryModel.fromJson(
                    row as Map<String, dynamic>),
                book: BookModel.fromJson(row['books'] as Map<String, dynamic>),
              ))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar tu historial de lectura: $e');
    }
  }

  /// Crea o actualiza (upsert) el registro de progreso de lectura de
  /// un libro para el usuario dado. `ultima_lectura` la actualiza
  /// automáticamente el trigger `trg_reading_history_actualizado` en
  /// la base de datos, así que no se envía desde aquí.
  Future<void> saveProgress({
    required String userId,
    required String bookId,
    required int lastPageRead,
    int? totalPages,
  }) async {
    try {
      final payload = <String, dynamic>{
        'usuario_id': userId,
        'libro_id': bookId,
        'ultima_pagina': lastPageRead,
      };

      if (totalPages != null && totalPages > 0) {
        payload['porcentaje_completado'] =
            ((lastPageRead / totalPages) * 100).clamp(0, 100);
        payload['completado'] = lastPageRead >= totalPages;
      }

      await _client
          .from(AppConstants.tableReadingHistory)
          .upsert(payload, onConflict: 'libro_id,usuario_id');
    } catch (e) {
      throw AppException('No fue posible guardar tu progreso de lectura: $e');
    }
  }
}

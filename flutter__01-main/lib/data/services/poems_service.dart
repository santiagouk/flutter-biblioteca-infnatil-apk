import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/poem_model.dart';
import 'supabase_client_service.dart';

/// Servicio de acceso a datos para el Foro de Poemas.
///
/// Los conteos y promedios (likes, calificaciones) se leen ya
/// calculados desde la vista `poemas_con_estadisticas` en vez de
/// calcularlos en el cliente. Los créditos por "me gusta" y por
/// calificación los otorgan triggers en el servidor — este servicio
/// nunca escribe en `credit_transactions` ni en `profiles.creditos`
/// directamente.
class PoemsService {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<PoemModel>> fetchAll() async {
    try {
      final data = await _client
          .from(AppConstants.viewPoemsWithStats)
          .select()
          .order('creado_en', ascending: false);
      return _mapList(data);
    } catch (e) {
      throw AppException('No fue posible cargar el Foro de Poemas: $e');
    }
  }

  Future<List<PoemModel>> fetchMine(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.viewPoemsWithStats)
          .select()
          .eq('usuario_id', userId)
          .order('creado_en', ascending: false);
      return _mapList(data);
    } catch (e) {
      throw AppException('No fue posible cargar tus poemas: $e');
    }
  }

  Future<PoemModel> create({
    required String userId,
    required String titulo,
    required String contenido,
    required String nombreAutor,
  }) async {
    try {
      final inserted = await _client
          .from(AppConstants.tablePoems)
          .insert({
            'usuario_id': userId,
            'titulo': titulo.trim(),
            'contenido': contenido.trim(),
            'nombre_autor': nombreAutor.trim(),
          })
          .select()
          .single();
      // La vista con estadísticas es la fuente de verdad para la UI,
      // así que releemos el poema recién creado desde ahí (empieza en
      // 0 likes / 0 calificaciones).
      final withStats = await _client
          .from(AppConstants.viewPoemsWithStats)
          .select()
          .eq('id', inserted['id'] as String)
          .single();
      return PoemModel.fromJson(withStats);
    } catch (e) {
      throw AppException('No fue posible publicar tu poema: $e');
    }
  }

  /// Elimina un poema propio, o cualquiera si quien elimina es
  /// moderador/admin (permitido por las políticas RLS correspondientes).
  Future<void> delete(String poemId) async {
    try {
      await _client.from(AppConstants.tablePoems).delete().eq('id', poemId);
    } catch (e) {
      throw AppException('No fue posible eliminar el poema: $e');
    }
  }

  Future<bool> hasLiked({required String userId, required String poemId}) async {
    try {
      final data = await _client
          .from(AppConstants.tablePoemLikes)
          .select('id')
          .eq('usuario_id', userId)
          .eq('poema_id', poemId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      throw AppException('No fue posible verificar tu me gusta: $e');
    }
  }

  /// Alterna el "me gusta" de un poema. Un trigger del servidor
  /// bloquea que el autor se dé like a sí mismo (autointeracción) y
  /// otorga/revoca el crédito correspondiente automáticamente.
  Future<bool> toggleLike({required String userId, required String poemId}) async {
    final already = await hasLiked(userId: userId, poemId: poemId);
    try {
      if (already) {
        await _client
            .from(AppConstants.tablePoemLikes)
            .delete()
            .eq('usuario_id', userId)
            .eq('poema_id', poemId);
        return false;
      }
      await _client.from(AppConstants.tablePoemLikes).insert({
        'usuario_id': userId,
        'poema_id': poemId,
      });
      return true;
    } catch (e) {
      throw AppException(
        'No fue posible actualizar tu me gusta. Recuerda que no puedes '
        'darle me gusta a tu propio poema. $e',
      );
    }
  }

  Future<int?> fetchMyRating({
    required String userId,
    required String poemId,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.tablePoemRatings)
          .select('estrellas')
          .eq('usuario_id', userId)
          .eq('poema_id', poemId)
          .maybeSingle();
      return data == null ? null : data['estrellas'] as int;
    } catch (e) {
      throw AppException('No fue posible cargar tu calificación: $e');
    }
  }

  /// Crea o actualiza (upsert) la calificación de 1 a 5 estrellas del
  /// usuario sobre un poema. El trigger del servidor bloquea
  /// autocalificación y gestiona el crédito por calificación positiva.
  Future<void> rate({
    required String userId,
    required String poemId,
    required int estrellas,
  }) async {
    try {
      await _client.from(AppConstants.tablePoemRatings).upsert(
        {
          'usuario_id': userId,
          'poema_id': poemId,
          'estrellas': estrellas,
        },
        onConflict: 'poema_id,usuario_id',
      );
    } catch (e) {
      throw AppException(
        'No fue posible guardar tu calificación. Recuerda que no puedes '
        'calificar tu propio poema. $e',
      );
    }
  }

  Future<void> report({
    required String userId,
    required String poemId,
    required String motivo,
  }) async {
    try {
      await _client.from(AppConstants.tablePoemReports).insert({
        'usuario_id': userId,
        'poema_id': poemId,
        'motivo': motivo.trim(),
      });
    } catch (e) {
      throw AppException('No fue posible enviar tu reporte: $e');
    }
  }

  /// Solo accesible para admin/moderador (RLS de `poem_reports`).
  Future<List<PoemReportModel>> fetchReports() async {
    try {
      final data = await _client
          .from(AppConstants.tablePoemReports)
          .select()
          .order('creado_en', ascending: false);
      return (data as List)
          .map((row) => PoemReportModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar los reportes: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _client
          .from(AppConstants.tablePoemReports)
          .delete()
          .eq('id', reportId);
    } catch (e) {
      throw AppException('No fue posible descartar el reporte: $e');
    }
  }

  Future<PoemUserStatsModel> fetchUserStats(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.viewUserPoemStats)
          .select()
          .eq('usuario_id', userId)
          .maybeSingle();
      return data == null
          ? PoemUserStatsModel.empty()
          : PoemUserStatsModel.fromJson(data);
    } catch (e) {
      throw AppException('No fue posible cargar tus estadísticas: $e');
    }
  }

  List<PoemModel> _mapList(dynamic data) {
    return (data as List)
        .map((row) => PoemModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';
import 'supabase_client_service.dart';

/// Servicio de acceso a datos para el panel de administrador:
/// listado de usuarios y cambio de rol (admin / moderador / usuario).
///
/// El cambio de rol solo funciona si quien ejecuta la app es admin:
/// la política `profiles_update_propio` (protegida además por el
/// trigger `proteger_cambio_rol`) impide que un usuario normal se
/// autoasigne un rol distinto, y el resto de usuarios no pueden
/// actualizar filas de `profiles` que no sean la propia.
class AdminUserService {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<UserProfileModel>> fetchAll() async {
    try {
      final data = await _client
          .from(AppConstants.tableProfiles)
          .select()
          .order('creado_en', ascending: false);
      return (data as List)
          .map((row) => UserProfileModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar los usuarios: $e');
    }
  }

  Future<void> updateRole({required String userId, required String rol}) async {
    try {
      await _client
          .from(AppConstants.tableProfiles)
          .update({'rol': rol})
          .eq('id', userId);
    } catch (e) {
      throw AppException('No fue posible actualizar el rol: $e');
    }
  }

  Future<int> countAll() async {
    try {
      final data = await _client.from(AppConstants.tableProfiles).select('id');
      return (data as List).length;
    } catch (e) {
      throw AppException('No fue posible calcular las estadísticas: $e');
    }
  }
}

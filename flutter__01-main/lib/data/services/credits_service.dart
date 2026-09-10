import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/credit_transaction_model.dart';
import 'supabase_client_service.dart';

/// Servicio de acceso a datos para el sistema de créditos y libros
/// VIP (`credit_transactions`, `unlocked_vip_books`, y la función
/// `canjear_libro_vip`).
///
/// El saldo de créditos vive en `profiles.creditos` (ya incluido en
/// `UserProfileModel`, vía `AuthProvider`) — este servicio solo lee el
/// historial de movimientos y gestiona el canje de libros VIP.
class CreditsService {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<CreditTransactionModel>> fetchHistory(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.tableCreditTransactions)
          .select()
          .eq('usuario_id', userId)
          .order('creado_en', ascending: false);
      return (data as List)
          .map((row) =>
              CreditTransactionModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('No fue posible cargar tu historial de créditos: $e');
    }
  }

  Future<Set<String>> fetchUnlockedBookIds(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.tableUnlockedVipBooks)
          .select('libro_id')
          .eq('usuario_id', userId);
      return (data as List).map((row) => row['libro_id'] as String).toSet();
    } catch (e) {
      throw AppException('No fue posible verificar tus libros VIP: $e');
    }
  }

  /// Canjea créditos por el acceso a un libro VIP mediante la función
  /// `canjear_libro_vip`, que valida el saldo y registra tanto la
  /// transacción de créditos como el desbloqueo del lado del servidor.
  Future<VipRedeemResult> redeemVipBook(String bookId) async {
    try {
      final data = await _client.rpc(
        AppConstants.rpcCanjearLibroVip,
        params: {'p_libro_id': bookId},
      );
      final row = (data as List).first as Map<String, dynamic>;
      return VipRedeemResult.fromJson(row);
    } catch (e) {
      throw AppException('No fue posible canjear el libro: $e');
    }
  }
}

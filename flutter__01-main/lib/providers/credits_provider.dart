import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/models/credit_transaction_model.dart';
import '../data/services/credits_service.dart';

/// Provider que gestiona el historial de créditos y los libros VIP
/// que el usuario ya desbloqueó, con un pequeño caché en memoria para
/// no repetir la consulta de desbloqueo en cada pantalla.
class CreditsProvider extends ChangeNotifier {
  final CreditsService _service;

  CreditsProvider({CreditsService? service})
      : _service = service ?? CreditsService();

  List<CreditTransactionModel> _history = [];
  Set<String> _unlockedBookIds = {};
  bool _isLoadingHistory = false;
  String? _errorMessage;

  List<CreditTransactionModel> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;

  Future<void> loadHistory(String userId) async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _history = await _service.fetchHistory(userId);
      _unlockedBookIds = await _service.fetchUnlockedBookIds(userId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Verifica si un libro VIP ya está desbloqueado para [userId].
  /// Usa el caché en memoria si ya se cargó antes con [loadHistory];
  /// de lo contrario consulta directamente ese libro puntual.
  Future<bool> isBookUnlocked({
    required String userId,
    required String bookId,
  }) async {
    if (_unlockedBookIds.contains(bookId)) return true;
    try {
      _unlockedBookIds = await _service.fetchUnlockedBookIds(userId);
      return _unlockedBookIds.contains(bookId);
    } on AppException {
      return false;
    }
  }

  Future<VipRedeemResult> redeemVipBook({required String bookId}) async {
    try {
      final result = await _service.redeemVipBook(bookId);
      if (result.exito) {
        _unlockedBookIds.add(bookId);
        notifyListeners();
      }
      return result;
    } on AppException catch (e) {
      return VipRedeemResult(
        exito: false,
        mensaje: e.message,
        creditosRestantes: 0,
      );
    }
  }
}

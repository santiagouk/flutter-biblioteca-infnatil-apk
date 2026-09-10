import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/models/user_profile_model.dart';
import '../data/services/auth_service.dart';

/// Estados posibles del flujo de autenticación, usados por la UI para
/// decidir qué mostrar (spinner, formulario, error, contenido).
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Provider central de autenticación.
///
/// Expone el perfil del usuario autenticado (incluyendo su rol) a
/// toda la app, y ofrece métodos de alto nivel para login, registro,
/// recuperación de contraseña y cierre de sesión, manejando estados
/// de carga y error para que las pantallas solo necesiten reaccionar
/// a cambios de estado.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _bootstrap();
  }

  AuthStatus _status = AuthStatus.unknown;
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfileModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _userProfile?.isAdmin ?? false;

  /// Comprueba si ya existe una sesión activa al iniciar la app.
  Future<void> _bootstrap() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _userProfile = await _authService.fetchCurrentProfile();
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _runAuthAction(() async {
      _userProfile = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _runAuthAction(() async {
      _userProfile = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _runAuthAction(() async {
      await _authService.sendPasswordResetEmail(email);
    });
  }

  /// Vuelve a leer el perfil desde la base de datos y actualiza el
  /// estado local. Se usa después de acciones que cambian datos del
  /// perfil del lado del servidor (por ejemplo, canjear créditos por
  /// un libro VIP), para que la UI refleje el saldo real sin tener
  /// que cerrar y volver a abrir sesión.
  Future<void> refreshProfile() async {
    if (_status != AuthStatus.authenticated) return;
    try {
      _userProfile = await _authService.fetchCurrentProfile();
      notifyListeners();
    } catch (_) {
      // Si falla, se mantiene el perfil que ya había en memoria.
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Ejecuta una acción asíncrona de autenticación, centralizando el
  /// manejo de `isLoading` y `errorMessage` para evitar duplicar este
  /// código en cada método público.
  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }
}

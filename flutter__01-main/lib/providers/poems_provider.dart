import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/models/poem_model.dart';
import '../data/services/poems_service.dart';

/// Provider que gestiona el estado del Foro de Poemas: listado
/// general, "me gusta" y calificaciones del usuario actual sobre cada
/// poema visible en pantalla.
class PoemsProvider extends ChangeNotifier {
  final PoemsService _service;

  PoemsProvider({PoemsService? service}) : _service = service ?? PoemsService();

  List<PoemModel> _poems = [];
  final Set<String> _likedPoemIds = {};
  final Map<String, int> _myRatings = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<PoemModel> get poems => _poems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool hasLiked(String poemId) => _likedPoemIds.contains(poemId);
  int? myRatingFor(String poemId) => _myRatings[poemId];

  Future<void> loadAll(String? currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _poems = await _service.fetchAll();
      if (currentUserId != null) {
        await _preloadUserInteractions(currentUserId);
      }
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'No fue posible cargar el Foro de Poemas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _preloadUserInteractions(String userId) async {
    for (final poem in _poems) {
      try {
        final liked = await _service.hasLiked(userId: userId, poemId: poem.id);
        if (liked) _likedPoemIds.add(poem.id);
        final rating =
            await _service.fetchMyRating(userId: userId, poemId: poem.id);
        if (rating != null) _myRatings[poem.id] = rating;
      } catch (_) {
        // Interacción informativa; si falla para un poema puntual,
        // seguimos con el resto sin bloquear la carga del foro.
      }
    }
  }

  Future<bool> publish({
    required String userId,
    required String titulo,
    required String contenido,
    required String nombreAutor,
  }) async {
    try {
      final poem = await _service.create(
        userId: userId,
        titulo: titulo,
        contenido: contenido,
        nombreAutor: nombreAutor,
      );
      _poems = [poem, ..._poems];
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> deletePoem(String poemId) async {
    try {
      await _service.delete(poemId);
      _poems = _poems.where((p) => p.id != poemId).toList();
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> toggleLike({required String userId, required PoemModel poem}) async {
    try {
      final nowLiked =
          await _service.toggleLike(userId: userId, poemId: poem.id);
      final delta = nowLiked ? 1 : -1;
      _poems = _poems
          .map((p) => p.id == poem.id
              ? PoemModel(
                  id: p.id,
                  usuarioId: p.usuarioId,
                  titulo: p.titulo,
                  contenido: p.contenido,
                  nombreAutor: p.nombreAutor,
                  totalLikes: p.totalLikes + delta,
                  totalCalificaciones: p.totalCalificaciones,
                  promedioEstrellas: p.promedioEstrellas,
                  creadoEn: p.creadoEn,
                )
              : p)
          .toList();
      if (nowLiked) {
        _likedPoemIds.add(poem.id);
      } else {
        _likedPoemIds.remove(poem.id);
      }
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> rate({
    required String userId,
    required String poemId,
    required int estrellas,
  }) async {
    try {
      await _service.rate(userId: userId, poemId: poemId, estrellas: estrellas);
      _myRatings[poemId] = estrellas;
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<bool> report({
    required String userId,
    required String poemId,
    required String motivo,
  }) async {
    try {
      await _service.report(userId: userId, poemId: poemId, motivo: motivo);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}

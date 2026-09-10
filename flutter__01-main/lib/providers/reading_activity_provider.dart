import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/models/book_model.dart';
import '../data/models/reading_activity_model.dart';
import '../data/services/reading_activity_service.dart';

/// Provider que gestiona los favoritos y el historial de lectura del
/// usuario autenticado.
///
/// Mantiene un `Set<String>` de IDs de libros favoritos en memoria
/// para que [isFavorite] sea instantáneo en la UI (por ejemplo, para
/// pintar el ícono de corazón en la pantalla de detalle) sin tener
/// que esperar una consulta de red en cada rebuild.
class ReadingActivityProvider extends ChangeNotifier {
  final ReadingActivityService _service;

  ReadingActivityProvider({ReadingActivityService? service})
      : _service = service ?? ReadingActivityService();

  List<BookModel> _favoriteBooks = [];
  List<ReadingHistoryModel> _history = [];
  List<ReadingHistoryEntry> _historyEntries = [];
  final Set<String> _favoriteBookIds = {};

  bool _isLoadingFavorites = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  List<BookModel> get favoriteBooks => _favoriteBooks;
  List<ReadingHistoryModel> get history => _history;
  List<ReadingHistoryEntry> get historyEntries => _historyEntries;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String bookId) => _favoriteBookIds.contains(bookId);

  /// Consulta puntual el estado de favorito de un libro específico
  /// (usado en el detalle del libro cuando el caché de favoritos aún
  /// no se ha cargado) y actualiza el caché local.
  Future<bool> checkIsFavorite(String userId, String bookId) async {
    final result = await _service.isFavorite(userId, bookId);
    if (result) {
      _favoriteBookIds.add(bookId);
    } else {
      _favoriteBookIds.remove(bookId);
    }
    notifyListeners();
    return result;
  }

  /// Devuelve la última página leída de un libro según el historial
  /// ya cargado, o 0 si no hay registro previo.
  int lastPageFor(String bookId) {
    final match = _history.where((h) => h.libroId == bookId);
    return match.isEmpty ? 0 : match.first.ultimaPagina;
  }

  Future<void> loadFavorites(String userId) async {
    _isLoadingFavorites = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _favoriteBooks = await _service.fetchFavoriteBooks(userId);
      _favoriteBookIds
        ..clear()
        ..addAll(_favoriteBooks.map((book) => book.id));
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String userId) async {
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchHistory(userId),
        _service.fetchHistoryEntries(userId),
      ]);
      _history = results[0] as List<ReadingHistoryModel>;
      _historyEntries = results[1] as List<ReadingHistoryEntry>;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Alterna el estado de favorito de un libro, actualizando el
  /// estado local de forma optimista para una UI ágil.
  Future<void> toggleFavorite({
    required String userId,
    required BookModel book,
  }) async {
    try {
      final nowFavorite = await _service.toggleFavorite(userId, book.id);
      if (nowFavorite) {
        _favoriteBookIds.add(book.id);
        if (!_favoriteBooks.any((b) => b.id == book.id)) {
          _favoriteBooks = [book, ..._favoriteBooks];
        }
      } else {
        _favoriteBookIds.remove(book.id);
        _favoriteBooks =
            _favoriteBooks.where((b) => b.id != book.id).toList();
      }
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> saveReadingProgress({
    required String userId,
    required String bookId,
    required int lastPageRead,
    int? totalPages,
  }) async {
    try {
      await _service.saveProgress(
        userId: userId,
        bookId: bookId,
        lastPageRead: lastPageRead,
        totalPages: totalPages,
      );
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Limpia el estado guardado localmente (usado al cerrar sesión).
  void reset() {
    _favoriteBooks = [];
    _history = [];
    _historyEntries = [];
    _favoriteBookIds.clear();
    notifyListeners();
  }
}

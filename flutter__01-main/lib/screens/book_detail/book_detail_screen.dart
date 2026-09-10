import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/book_comment_model.dart';
import '../../data/models/book_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/book_service.dart';
import '../../data/services/book_social_service.dart';
import '../../data/services/category_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credits_provider.dart';
import '../../providers/reading_activity_provider.dart';
import '../../widgets/book/book_comments_section.dart';

/// Pantalla de detalle de un libro: muestra portada, título, autor,
/// categoría y descripción completa, además de accesos directos para
/// leerlo dentro de la app, marcarlo como favorito, darle me gusta y
/// comentarlo ("¿Qué te pareció este libro?").
class BookDetailScreen extends StatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  final CategoryService _categoryService = CategoryService();
  final BookSocialService _socialService = BookSocialService();

  BookModel? _book;
  CategoryModel? _category;
  bool _isLoading = true;
  String? _errorMessage;

  int _likeCount = 0;
  bool _hasLiked = false;
  bool _isVipUnlocked = false;
  List<BookCommentModel> _comments = [];
  bool _isLoadingSocial = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final book = await _bookService.fetchById(widget.bookId);
      CategoryModel? category;
      try {
        final categories = await _categoryService.fetchAll();
        for (final element in categories) {
          if (element.id == book.categoriaId) {
            category = element;
            break;
          }
        }
      } catch (_) {
        // La categoría es informativa; si falla, seguimos mostrando el libro.
      }
      if (!mounted) return;
      setState(() {
        _book = book;
        _category = category;
        _isLoading = false;
      });
      _loadSocial(book.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar este libro.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSocial(String bookId) async {
    setState(() => _isLoadingSocial = true);
    final userId = context.read<AuthProvider>().userProfile?.id;
    try {
      final results = await Future.wait([
        _socialService.fetchLikeCount(bookId),
        _socialService.fetchComments(bookId),
        if (userId != null) _socialService.hasLiked(userId: userId, bookId: bookId),
      ]);
      if (!mounted) return;
      setState(() {
        _likeCount = results[0] as int;
        _comments = results[1] as List<BookCommentModel>;
        _hasLiked = userId != null ? results[2] as bool : false;
        _isLoadingSocial = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSocial = false);
    }

    final book = _book;
    if (book != null && book.esVip && userId != null) {
      final unlocked = await context
          .read<CreditsProvider>()
          .isBookUnlocked(userId: userId, bookId: book.id);
      if (mounted) setState(() => _isVipUnlocked = unlocked);
    }
  }

  Future<void> _toggleLike() async {
    final userId = context.read<AuthProvider>().userProfile?.id;
    final book = _book;
    if (userId == null || book == null) return;
    setState(() {
      _hasLiked = !_hasLiked;
      _likeCount += _hasLiked ? 1 : -1;
    });
    try {
      await _socialService.toggleLike(userId: userId, bookId: book.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasLiked = !_hasLiked;
        _likeCount += _hasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _addComment(String texto) async {
    final auth = context.read<AuthProvider>().userProfile;
    final book = _book;
    if (auth == null || book == null) return;
    try {
      final comment = await _socialService.addComment(
        userId: auth.id,
        bookId: book.id,
        nombreMostrado: auth.displayName,
        comentario: texto,
      );
      if (!mounted) return;
      setState(() => _comments = [comment, ..._comments]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _socialService.deleteComment(commentId);
      if (!mounted) return;
      setState(() => _comments = _comments.where((c) => c.id != commentId).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: AppLoadingIndicator(message: 'Cargando libro...'),
      );
    }
    if (_errorMessage != null || _book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppErrorState(
          message: _errorMessage ?? 'Libro no encontrado.',
          onRetry: _loadBook,
        ),
      );
    }

    final book = _book!;
    final auth = context.watch<AuthProvider>();
    final activity = context.watch<ReadingActivityProvider>();
    final isFavorite = activity.isFavorite(book.id);
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;
    final vipLockedForMe = book.esVip && !_isVipUnlocked;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.error : null,
            ),
            onPressed: () {
              final userId = auth.userProfile?.id;
              if (userId == null) return;
              context
                  .read<ReadingActivityProvider>()
                  .toggleFavorite(userId: userId, book: book);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWideScreen ? 640 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: 190,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: CachedNetworkImage(
                              imageUrl: book.portadaUrl ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.lightSurfaceVariant,
                                child: const Icon(Icons.menu_book_rounded,
                                    size: 48),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).scale(
                            begin: const Offset(0.94, 0.94),
                            end: const Offset(1, 1),
                          ),
                      if (book.esVip)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    size: 14, color: Colors.black87),
                                const SizedBox(width: 4),
                                Text(
                                  'VIP · ${book.costoCreditos}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    book.titulo,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'por ${book.autor}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_category != null)
                        Chip(
                          label: Text(_category!.nombre),
                          backgroundColor:
                              AppColors.accentPurple.withOpacity(0.15),
                          side: BorderSide.none,
                        ),
                      Chip(
                        avatar: const Icon(Icons.child_care_rounded, size: 18),
                        label: Text('Edad ${book.edadRecomendada} años'),
                        backgroundColor:
                            AppColors.accentGreen.withOpacity(0.15),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sobre este libro',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (book.sinopsis?.isNotEmpty ?? false)
                        ? book.sinopsis!
                        : (book.descripcion?.isNotEmpty ?? false)
                            ? book.descripcion!
                            : 'Este libro todavía no tiene una descripción.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: vipLockedForMe ? 'Ver detalles VIP' : 'Leer ahora',
                    icon: vipLockedForMe
                        ? Icons.workspace_premium_rounded
                        : Icons.menu_book_rounded,
                    onPressed: () =>
                        context.push(AppRoutes.readerPath(book.id)),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BookCommentsSection(
                      likeCount: _likeCount,
                      hasLiked: _hasLiked,
                      onToggleLike: _toggleLike,
                      comments: _comments,
                      isLoading: _isLoadingSocial,
                      currentUserId: auth.userProfile?.id ?? '',
                      canModerateAny:
                          auth.userProfile?.canModerate ?? false,
                      onAddComment: _addComment,
                      onDeleteComment: _deleteComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

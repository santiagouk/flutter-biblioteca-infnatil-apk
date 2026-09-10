import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/book_model.dart';
import '../../data/services/book_service.dart';

/// Listado administrativo de libros, con acceso a crear/editar/eliminar.
class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final BookService _bookService = BookService();
  List<BookModel> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final books = await _bookService.fetchAll();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar los libros: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar libro?'),
        content: Text('Se eliminará "${book.titulo}" permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _bookService.delete(book.id);
      if (!mounted) return;
      setState(() => _books = _books.where((b) => b.id != book.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Libros')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await context.push<bool>(AppRoutes.adminBookForm);
          if (saved == true) _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo libro'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator(message: 'Cargando libros...')
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _load)
                : _books.isEmpty
                    ? const AppEmptyState(message: 'Todavía no hay libros.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: _books.length,
                          itemBuilder: (context, index) {
                            final book = _books[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 44,
                                    height: 56,
                                    child: CachedNetworkImage(
                                      imageUrl: book.portadaUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.lightSurfaceVariant,
                                        child: const Icon(
                                            Icons.menu_book_rounded,
                                            size: 20),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(book.titulo, maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  [
                                    book.autor,
                                    if (!book.publicado) 'Sin publicar',
                                    if (book.esVip)
                                      'VIP · ${book.costoCreditos} créditos',
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: () async {
                                        final saved = await context.push<bool>(
                                          AppRoutes.adminBookForm,
                                          extra: book,
                                        );
                                        if (saved == true) _load();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded,
                                          color: AppColors.error),
                                      onPressed: () => _confirmDelete(book),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

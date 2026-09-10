import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/book/book_cover_card.dart';

/// Pantalla de búsqueda de libros por título o autor.
///
/// Usa un `Timer` para aplicar debounce: la búsqueda solo se dispara
/// [AppConstants.searchDebounceMillis] después de que el usuario deja
/// de escribir, evitando peticiones innecesarias a Supabase en cada
/// pulsación de tecla.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMillis),
      () {
        final catalog = context.read<CatalogProvider>();
        if (query.trim().isEmpty) {
          catalog.clearSearch();
        } else {
          catalog.search(query.trim());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final hasQuery = _controller.text.trim().isNotEmpty;
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Busca por título o autor...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                context.read<CatalogProvider>().clearSearch();
                setState(() {});
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isWideScreen ? 900 : double.infinity),
          child: Builder(
            builder: (context) {
              if (!hasQuery) {
                return const AppEmptyState(
                  message: 'Escribe el título o el autor de un libro para '
                      'empezar a buscar.',
                  icon: Icons.search_rounded,
                );
              }
              if (catalog.isSearching) {
                return const AppLoadingIndicator(message: 'Buscando...');
              }
              if (catalog.searchResults.isEmpty) {
                return const AppEmptyState(
                  message: 'No encontramos libros que coincidan con tu '
                      'búsqueda.',
                  icon: Icons.sentiment_neutral_rounded,
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: catalog.searchResults.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final book = catalog.searchResults[index];
                  return BookCoverCard(
                    book: book,
                    animationIndex: index,
                    width: double.infinity,
                    onTap: () =>
                        context.push(AppRoutes.bookDetailPath(book.id)),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

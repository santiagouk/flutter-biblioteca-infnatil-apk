import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/book/book_cover_card.dart';

/// Pestaña "Catálogo": muestra TODOS los libros publicados (a
/// diferencia de Inicio, que solo muestra recomendados/destacados),
/// con un filtro rápido por categoría en la parte superior — igual
/// que las pestañas "Inicio"/"Catálogo" que ya existen en la versión
/// web de la Biblioteca Infantil.
class CatalogScreen extends StatefulWidget {
  final String? initialCategoryId;
  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CatalogProvider>()
          .loadCatalog(categoryId: widget.initialCategoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: catalog.catalogCategoryFilter == null,
                      onSelected: (_) => context
                          .read<CatalogProvider>()
                          .loadCatalog(),
                    ),
                  ),
                  ...catalog.categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.nombre),
                        selected: catalog.catalogCategoryFilter == category.id,
                        onSelected: (_) => context
                            .read<CatalogProvider>()
                            .loadCatalog(categoryId: category.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context
                    .read<CatalogProvider>()
                    .loadCatalog(categoryId: catalog.catalogCategoryFilter),
                child: catalog.isLoadingCatalog
                    ? const AppLoadingIndicator(message: 'Cargando catálogo...')
                    : catalog.errorMessage != null
                        ? AppErrorState(
                            message: catalog.errorMessage!,
                            onRetry: () => context
                                .read<CatalogProvider>()
                                .loadCatalog(
                                    categoryId: catalog.catalogCategoryFilter),
                          )
                        : catalog.catalogBooks.isEmpty
                            ? const AppEmptyState(
                                message: 'No hay libros en esta categoría todavía.',
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: catalog.catalogBooks.length,
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: isWideScreen ? 170 : 150,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.62,
                                ),
                                itemBuilder: (context, index) {
                                  final book = catalog.catalogBooks[index];
                                  return BookCoverCard(
                                    book: book,
                                    animationIndex: index % 12,
                                    width: double.infinity,
                                    onTap: () => context
                                        .push(AppRoutes.bookDetailPath(book.id)),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

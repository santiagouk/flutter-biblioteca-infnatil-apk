import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/book/book_cover_card.dart';
import '../../widgets/category/category_chip.dart';

/// Pantalla principal de la app: saluda al usuario, muestra las
/// categorías disponibles y los libros destacados del catálogo.
///
/// Es totalmente responsive: en pantallas anchas (tablet/escritorio)
/// el contenido se limita a un ancho máximo cómodo de lectura y los
/// libros destacados se muestran en una grilla en lugar de una fila.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.userProfile?.displayName ?? 'Lector')
        .split(' ')
        .first;
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<CatalogProvider>().loadHomeData(),
          child: catalog.isLoadingHome
              ? const AppLoadingIndicator(message: 'Cargando tu biblioteca...')
              : catalog.errorMessage != null
                  ? AppErrorState(
                      message: catalog.errorMessage!,
                      onRetry: () =>
                          context.read<CatalogProvider>().loadHomeData(),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 900 : double.infinity,
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          children: [
                            _buildHeader(context, firstName),
                            const SizedBox(height: 24),
                            Text('Categorías',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: catalog.categories.isEmpty
                                  ? const AppEmptyState(
                                      message: 'Aún no hay categorías creadas.',
                                      icon: Icons.category_rounded,
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: catalog.categories.length,
                                      itemBuilder: (context, index) {
                                        final category =
                                            catalog.categories[index];
                                        return CategoryChip(
                                          category: category,
                                          colorIndex: index,
                                          animationIndex: index,
                                          onTap: () => context.push(
                                            AppRoutes.catalog,
                                            extra: category.id,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 28),
                            Text('Libros destacados',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            catalog.featuredBooks.isEmpty
                                ? const AppEmptyState(
                                    message:
                                        'Todavía no hay libros destacados.',
                                  )
                                : isWideScreen
                                    ? _buildFeaturedGrid(catalog)
                                    : _buildFeaturedRow(catalog),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String firstName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, $firstName! 👋',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 4),
              Text(
                '¿Qué historia quieres leer hoy?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.search),
          icon: const Icon(Icons.search_rounded, size: 28),
          tooltip: 'Buscar libros',
        ),
      ],
    );
  }

  Widget _buildFeaturedRow(CatalogProvider catalog) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: catalog.featuredBooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final book = catalog.featuredBooks[index];
          return BookCoverCard(
            book: book,
            animationIndex: index,
            onTap: () => context.push(AppRoutes.bookDetailPath(book.id)),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedGrid(CatalogProvider catalog) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: catalog.featuredBooks.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final book = catalog.featuredBooks[index];
        return BookCoverCard(
          book: book,
          animationIndex: index,
          width: double.infinity,
          onTap: () => context.push(AppRoutes.bookDetailPath(book.id)),
        );
      },
    );
  }
}

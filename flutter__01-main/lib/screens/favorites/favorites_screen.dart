import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reading_activity_provider.dart';
import '../../widgets/book/book_cover_card.dart';

/// Pantalla de favoritos: muestra en una grilla responsive todos los
/// libros que el usuario ha marcado con el ícono de corazón.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userProfile?.id;
      if (userId != null) {
        context.read<ReadingActivityProvider>().loadFavorites(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ReadingActivityProvider>();
    final userId = context.watch<AuthProvider>().userProfile?.id;
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userId != null) {
            await context.read<ReadingActivityProvider>().loadFavorites(userId);
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWideScreen ? 900 : double.infinity),
            child: Builder(
              builder: (context) {
                if (activity.isLoadingFavorites) {
                  return const AppLoadingIndicator(
                      message: 'Cargando tus favoritos...');
                }
                if (activity.errorMessage != null) {
                  return AppErrorState(
                    message: activity.errorMessage!,
                    onRetry: () {
                      if (userId != null) {
                        context
                            .read<ReadingActivityProvider>()
                            .loadFavorites(userId);
                      }
                    },
                  );
                }
                if (activity.favoriteBooks.isEmpty) {
                  return const AppEmptyState(
                    message:
                        'Aún no tienes libros favoritos.\nToca el corazón en '
                        'cualquier libro para guardarlo aquí.',
                    icon: Icons.favorite_border_rounded,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: activity.favoriteBooks.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final book = activity.favoriteBooks[index];
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
      ),
    );
  }
}

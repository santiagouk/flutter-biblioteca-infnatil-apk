import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/poem_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poems_provider.dart';
import '../../widgets/poem/poem_card.dart';

/// Pestaña "Foro de Poemas": lista todos los poemas publicados por
/// los usuarios, con calificación de 1 a 5 estrellas y "me gusta".
/// Publicar poemas, recibir "me gusta" y buenas calificaciones otorga
/// créditos (gestionado del lado del servidor) que luego se pueden
/// canjear por libros VIP.
class PoemsListScreen extends StatefulWidget {
  const PoemsListScreen({super.key});

  @override
  State<PoemsListScreen> createState() => _PoemsListScreenState();
}

class _PoemsListScreenState extends State<PoemsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userProfile?.id;
      context.read<PoemsProvider>().loadAll(userId);
    });
  }

  void _openPoem(PoemModel poem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PoemDetailSheet(poem: poem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poems = context.watch<PoemsProvider>();
    final userId = context.watch<AuthProvider>().userProfile?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Foro de Poemas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.poemForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publicar poema'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<PoemsProvider>().loadAll(userId),
          child: poems.isLoading
              ? const AppLoadingIndicator(message: 'Cargando poemas...')
              : poems.errorMessage != null
                  ? AppErrorState(
                      message: poems.errorMessage!,
                      onRetry: () =>
                          context.read<PoemsProvider>().loadAll(userId),
                    )
                  : poems.poems.isEmpty
                      ? const AppEmptyState(
                          message:
                              'Todavía no hay poemas publicados. ¡Sé el primero!',
                          icon: Icons.auto_stories_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          itemCount: poems.poems.length,
                          itemBuilder: (context, index) {
                            final poem = poems.poems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PoemCard(
                                poem: poem,
                                hasLiked: poems.hasLiked(poem.id),
                                isOwnPoem: poem.usuarioId == userId,
                                myRating: poems.myRatingFor(poem.id),
                                onTap: () => _openPoem(poem),
                                onToggleLike: () {
                                  if (userId == null) return;
                                  context.read<PoemsProvider>().toggleLike(
                                      userId: userId, poem: poem);
                                },
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

/// Hoja inferior con el poema completo, calificación de 1 a 5
/// estrellas, y acciones de reportar / eliminar (propio o moderación).
class _PoemDetailSheet extends StatefulWidget {
  final PoemModel poem;
  const _PoemDetailSheet({required this.poem});

  @override
  State<_PoemDetailSheet> createState() => _PoemDetailSheetState();
}

class _PoemDetailSheetState extends State<_PoemDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().userProfile;
    final poemsProvider = context.watch<PoemsProvider>();
    final poem = widget.poem;
    final isOwn = auth?.id == poem.usuarioId;
    final myRating = poemsProvider.myRatingFor(poem.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: scrollController,
          children: [
            Text(poem.titulo, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('por ${poem.nombreAutor}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text(poem.contenido, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            if (!isOwn) ...[
              Text('Tu calificación',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = myRating != null && star <= myRating;
                  return IconButton(
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      final userId = auth?.id;
                      if (userId == null) return;
                      context.read<PoemsProvider>().rate(
                            userId: userId,
                            poemId: poem.id,
                            estrellas: star,
                          );
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showReportDialog(context, poem.id),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Reportar poema'),
              ),
            ],
            if (isOwn || (auth?.canModerate ?? false)) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Eliminar poema?'),
                      content: const Text('Esta acción no se puede deshacer.'),
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
                  if (confirmed == true && context.mounted) {
                    await context.read<PoemsProvider>().deletePoem(poem.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Eliminar poema'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context, String poemId) async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar poema'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '¿Por qué quieres reportar este poema?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.trim().isEmpty || !context.mounted) return;
    final userId = context.read<AuthProvider>().userProfile?.id;
    if (userId == null) return;
    final ok = await context
        .read<PoemsProvider>()
        .report(userId: userId, poemId: poemId, motivo: motivo);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Gracias, revisaremos tu reporte.'
              : 'No fue posible enviar el reporte.'),
        ),
      );
    }
  }
}

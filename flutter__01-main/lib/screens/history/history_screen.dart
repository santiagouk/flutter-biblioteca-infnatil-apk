import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/reading_activity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reading_activity_provider.dart';

/// Pantalla de historial de lectura: muestra, del más reciente al más
/// antiguo, cada libro que el usuario ha empezado a leer junto con la
/// última página alcanzada y la fecha de la última lectura.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dateFormat = DateFormat('d MMM, y', 'es');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userProfile?.id;
      if (userId != null) {
        context.read<ReadingActivityProvider>().loadHistory(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ReadingActivityProvider>();
    final userId = context.watch<AuthProvider>().userProfile?.id;
    final isWideScreen = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de lectura')),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userId != null) {
            await context.read<ReadingActivityProvider>().loadHistory(userId);
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWideScreen ? 700 : double.infinity),
            child: Builder(
              builder: (context) {
                if (activity.isLoadingHistory) {
                  return const AppLoadingIndicator(
                      message: 'Cargando tu historial...');
                }
                if (activity.errorMessage != null) {
                  return AppErrorState(
                    message: activity.errorMessage!,
                    onRetry: () {
                      if (userId != null) {
                        context
                            .read<ReadingActivityProvider>()
                            .loadHistory(userId);
                      }
                    },
                  );
                }
                if (activity.historyEntries.isEmpty) {
                  return const AppEmptyState(
                    message:
                        'Todavía no has empezado a leer ningún libro.\n'
                        '¡Elige uno en Inicio para comenzar tu aventura!',
                    icon: Icons.history_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: activity.historyEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = activity.historyEntries[index];
                    return _HistoryTile(
                      entry: entry,
                      dateFormat: _dateFormat,
                      onTap: () => context
                          .push(AppRoutes.bookDetailPath(entry.book.id)),
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

class _HistoryTile extends StatelessWidget {
  final ReadingHistoryEntry entry;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.entry,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final book = entry.book;
    final history = entry.history;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 76,
                  child: CachedNetworkImage(
                    imageUrl: book.portadaUrl ?? '',
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.lightSurfaceVariant,
                      child: const Icon(Icons.menu_book_rounded, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Página ${history.ultimaPagina}'
                      '${history.completado ? ' · Completado' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(history.ultimaLectura),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accentPurple,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

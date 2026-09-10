import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/poem_model.dart';

/// Tarjeta que muestra un poema en la lista del Foro de Poemas: título,
/// autor, un fragmento del contenido, calificación promedio, total de
/// "me gusta" y un botón para dar/quitar "me gusta".
class PoemCard extends StatelessWidget {
  final PoemModel poem;
  final bool hasLiked;
  final bool isOwnPoem;
  final int? myRating;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;

  const PoemCard({
    super.key,
    required this.poem,
    required this.hasLiked,
    required this.isOwnPoem,
    required this.myRating,
    required this.onTap,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final excerpt = poem.contenido.length > 140
        ? '${poem.contenido.substring(0, 140)}...'
        : poem.contenido;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poem.titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwnPoem)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Tuyo', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'por ${poem.nombreAutor}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Text(
                excerpt,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < poem.promedioEstrellas.round();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 18,
                        color: AppColors.accentYellow,
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Text('(${poem.totalCalificaciones})',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  InkWell(
                    onTap: isOwnPoem ? null : onToggleLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Icon(
                            hasLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: hasLiked ? AppColors.error : null,
                          ),
                          const SizedBox(width: 4),
                          Text('${poem.totalLikes}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/book_model.dart';

/// Tarjeta que representa un libro dentro de listas horizontales o
/// grillas (destacados, resultados de búsqueda, favoritos).
///
/// Incluye una animación de aparición suave (fade + desplazamiento)
/// escalonada mediante [animationIndex], para que las listas de
/// libros "entren" de forma agradable en pantalla sin distraer.
class BookCoverCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;
  final int animationIndex;
  final double width;

  const BookCoverCard({
    super.key,
    required this.book,
    required this.onTap,
    this.animationIndex = 0,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final card = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CachedNetworkImage(
                  imageUrl: book.portadaUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.lightSurfaceVariant,
                    highlightColor: Colors.white,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.lightSurfaceVariant,
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.accentPurple,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              book.autor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return card
        .animate(delay: (animationIndex * 60).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

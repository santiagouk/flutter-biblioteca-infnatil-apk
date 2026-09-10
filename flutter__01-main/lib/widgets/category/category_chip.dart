import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';

/// Mapa de nombres lógicos de ícono (almacenados en la columna
/// `icono` de `categories`) a íconos reales de Material Design. Si el
/// nombre no se reconoce, se usa un ícono de libro por defecto.
IconData _iconForCategory(String? iconName) {
  const mapping = <String, IconData>{
    'adventure': Icons.explore_rounded,
    'fantasy': Icons.auto_awesome_rounded,
    'animals': Icons.pets_rounded,
    'science': Icons.science_rounded,
    'values': Icons.favorite_rounded,
    'classic': Icons.castle_rounded,
    'space': Icons.rocket_launch_rounded,
    'ocean': Icons.water_rounded,
  };
  return mapping[iconName] ?? Icons.menu_book_rounded;
}

/// Convierte un color en formato "#RRGGBB" (tal como se guarda en
/// `categories.color`) a un [Color] de Flutter. Si el formato no es
/// válido, recurre a la paleta de respaldo de la app.
Color _colorFromHex(String? hex, int fallbackIndex) {
  if (hex != null && hex.isNotEmpty) {
    final cleanHex = hex.replaceFirst('#', '');
    final parsed = int.tryParse('FF$cleanHex', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return AppColors.categoryColorFor(fallbackIndex);
}

/// Tarjeta circular/redondeada que representa una categoría infantil,
/// con color propio y una pequeña animación de "pop" al aparecer.
class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final int colorIndex;
  final VoidCallback onTap;
  final int animationIndex;

  const CategoryChip({
    super.key,
    required this.category,
    required this.colorIndex,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(category.colorHex, colorIndex);

    final chip = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForCategory(category.icono),
                  color: color, size: 30),
            ),
            const SizedBox(height: 6),
            Text(
              category.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return chip
        .animate(delay: (animationIndex * 60).ms)
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pantalla temporal para secciones planificadas en fases posteriores
/// de desarrollo (ver Fases 2, 3 y 4 del plan del proyecto).
///
/// Se usa únicamente para que la navegación de la app quede completa
/// y ejecutable desde la Fase 1, dejando explícito en la propia UI
/// qué funcionalidad llega en la siguiente entrega.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    this.description = 'Esta sección se implementará en la próxima fase.',
    this.icon = Icons.construction_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: AppColors.accentPurple),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

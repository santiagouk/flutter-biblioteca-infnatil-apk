import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/book_model.dart';

/// Tarjeta de "libro VIP bloqueado", mostrada en lugar del lector
/// cuando el libro es VIP y el usuario todavía no lo ha desbloqueado.
///
/// Nota de arquitectura (heredada de la versión web): el bucket
/// `libros-pdf` es público, así que este candado es una barrera de UX
/// en el cliente, no una restricción real a nivel de archivo. Una
/// solución completa requeriría un bucket privado con URLs firmadas.
class VipLockCard extends StatelessWidget {
  final BookModel book;
  final int creditosDisponibles;
  final VoidCallback onRedeem;

  const VipLockCard({
    super.key,
    required this.book,
    required this.creditosDisponibles,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final alcanza = creditosDisponibles >= book.costoCreditos;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        color: AppColors.darkBackground,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.accentYellow, size: 56),
              const SizedBox(height: 16),
              Text(
                'Libro VIP',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                book.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(
                    label: 'Costo',
                    value: '${book.costoCreditos} créditos',
                  ),
                  _StatColumn(
                    label: 'Tu saldo',
                    value: '$creditosDisponibles créditos',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: alcanza ? 'Canjear y leer' : 'Créditos insuficientes',
                icon: Icons.lock_open_rounded,
                onPressed: alcanza ? onRedeem : null,
              ),
              if (!alcanza) ...[
                const SizedBox(height: 12),
                const Text(
                  'Gana créditos publicando poemas en el Foro de Poemas, '
                  'recibiendo "me gusta" o buenas calificaciones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

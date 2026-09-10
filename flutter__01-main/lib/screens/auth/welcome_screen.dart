import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';

/// Pantalla de bienvenida: primera impresión de la app para un
/// usuario nuevo. Presenta la propuesta de valor con una ilustración
/// alegre y dirige hacia Login o Registro.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWideScreen = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWideScreen ? 480 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _WelcomeIllustration(size: isWideScreen ? 220 : 180),
                  const SizedBox(height: 32),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 10),
                  Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                  ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                  const Spacer(flex: 2),
                  PrimaryButton(
                    label: 'Crear una cuenta',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => context.push(AppRoutes.register),
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.login),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Ya tengo una cuenta'),
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ilustración simple construida con formas e íconos (sin depender de
/// assets externos), representando libros y elementos mágicos.
class _WelcomeIllustration extends StatelessWidget {
  final double size;
  const _WelcomeIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: size,
            width: size,
            decoration: const BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          Icon(
            Icons.menu_book_rounded,
            size: size * 0.5,
            color: AppColors.primary,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          Positioned(
            top: size * 0.05,
            right: size * 0.05,
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.accentPurple,
              size: 28,
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                  duration: 800.ms,
                ),
          ),
          Positioned(
            bottom: size * 0.08,
            left: size * 0.02,
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.secondary,
              size: 24,
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                  delay: 300.ms,
                  duration: 800.ms,
                ),
          ),
        ],
      ),
    );
  }
}

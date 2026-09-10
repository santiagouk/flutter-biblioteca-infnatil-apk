import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de arranque: muestra el logo mientras [AuthProvider]
/// determina si existe una sesión activa, y redirige automáticamente
/// a Inicio o a Bienvenida según corresponda.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    // Pequeña espera para que la animación del logo se aprecie y para
    // dar tiempo a que AuthProvider resuelva el estado de sesión.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    // Si el estado sigue siendo "unknown", esperamos un poco más.
    var attempts = 0;
    while (authProvider.status.name == 'unknown' && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    if (!mounted) return;

    if (authProvider.status.name == 'authenticated') {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 96,
              color: Colors.white,
            ).animate().scale(
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ).then().shimmer(duration: 900.ms),
            const SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                  ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

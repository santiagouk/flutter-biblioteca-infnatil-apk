import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/admin_user_service.dart';
import '../../data/services/book_service.dart';
import '../../providers/auth_provider.dart';

/// Panel de administrador: accesos a la gestión de libros, categorías
/// y usuarios, más un pequeño resumen de estadísticas.
///
/// Accesible únicamente para `rol = 'admin'` (ya protegido en
/// `AppRouter._handleRedirect`). Los moderadores no ven este panel:
/// su único permiso adicional es eliminar comentarios/poemas ajenos,
/// ya cubierto directamente en las pantallas de libro y del foro.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final BookService _bookService = BookService();
  final AdminUserService _userService = AdminUserService();

  int? _bookCount;
  int? _userCount;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _bookService.countAll(),
        _userService.countAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _bookCount = results[0];
        _userCount = results[1];
      });
    } catch (_) {
      // Las estadísticas son informativas; si fallan no bloqueamos el panel.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<AuthProvider>().userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administrador')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Libros',
                        value: _bookCount?.toString() ?? '—',
                        color: AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        label: 'Usuarios',
                        value: _userCount?.toString() ?? '—',
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _AdminMenuTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Libros',
                  subtitle: 'Crear, editar y eliminar libros del catálogo',
                  onTap: () => context.push(AppRoutes.adminBooks),
                ),
                _AdminMenuTile(
                  icon: Icons.category_rounded,
                  title: 'Categorías',
                  subtitle: 'Gestionar las categorías infantiles',
                  onTap: () => context.push(AppRoutes.adminCategories),
                ),
                _AdminMenuTile(
                  icon: Icons.people_alt_rounded,
                  title: 'Usuarios',
                  subtitle: 'Administrar roles: admin, moderador, usuario',
                  onTap: () => context.push(AppRoutes.adminUsers),
                ),
                _AdminMenuTile(
                  icon: Icons.flag_rounded,
                  title: 'Reportes del Foro de Poemas',
                  subtitle: 'Revisar poemas reportados por la comunidad',
                  onTap: () => context.push(AppRoutes.adminPoemReports),
                ),
                if (userProfile != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Sesión: ${userProfile.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

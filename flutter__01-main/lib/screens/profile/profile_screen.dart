import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/poem_model.dart';
import '../../data/services/poems_service.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de perfil del usuario autenticado.
///
/// Muestra información de la cuenta, créditos disponibles y un
/// resumen de la actividad en el Foro de Poemas ("Mi actividad en el
/// Foro de Poemas", igual que en la versión web), además de accesos
/// directos a Buscar, Historial de lectura, historial de créditos y,
/// si corresponde, el panel de administrador.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _poemsService = PoemsService();
  PoemUserStatsModel? _poemStats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoemStats());
  }

  Future<void> _loadPoemStats() async {
    final userId = context.read<AuthProvider>().userProfile?.id;
    if (userId == null) return;
    try {
      final stats = await _poemsService.fetchUserStats(userId);
      if (mounted) setState(() => _poemStats = stats);
    } catch (_) {
      // Estadísticas informativas; si fallan, simplemente no se muestran.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProfile = auth.userProfile;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: const Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar libros',
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width > 700
                  ? 640
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.accentPurple.withOpacity(0.2),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AppColors.accentPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    userProfile.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProfile.email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta de créditos
                  Card(
                    color: AppColors.accentYellow.withOpacity(0.15),
                    child: ListTile(
                      leading: const Icon(Icons.toll_rounded,
                          color: AppColors.accentOrange),
                      title: Text('${userProfile.creditos} créditos'),
                      subtitle: const Text('Ver historial de créditos'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.creditHistory),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información de la cuenta
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información de la cuenta',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context,
                              label: 'ID',
                              value: '${userProfile.id.substring(0, 8)}...'),
                          const SizedBox(height: 12),
                          _buildInfoRow(context,
                              label: 'Rol', value: _roleLabel(userProfile.rol)),
                          const SizedBox(height: 12),
                          _buildInfoRow(context,
                              label: 'Miembro desde',
                              value: _formatDate(userProfile.creadoEn)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mi actividad en el Foro de Poemas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mi actividad en el Foro de Poemas',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              TextButton(
                                onPressed: () => context.push(AppRoutes.poems),
                                child: const Text('Ir al foro'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_poemStats == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            )
                          else
                            Row(
                              children: [
                                _PoemStat(
                                  label: 'Poemas',
                                  value: '${_poemStats!.totalPoemas}',
                                ),
                                _PoemStat(
                                  label: 'Me gusta recibidos',
                                  value: '${_poemStats!.totalLikesRecibidos}',
                                ),
                                _PoemStat(
                                  label: 'Calificación',
                                  value: _poemStats!.promedioCalificacion
                                      .toStringAsFixed(1),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Accesos directos
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.history_rounded),
                          title: const Text('Historial de lectura'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(AppRoutes.history),
                        ),
                        if (userProfile.isAdmin)
                          const Divider(height: 1),
                        if (userProfile.isAdmin)
                          ListTile(
                            leading: const Icon(
                                Icons.admin_panel_settings_rounded),
                            title: const Text('Panel de administrador'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push(AppRoutes.admin),
                          ),
                        if (userProfile.canModerate && !userProfile.isAdmin)
                          const Divider(height: 1),
                        if (userProfile.canModerate && !userProfile.isAdmin)
                          ListTile(
                            leading: const Icon(Icons.flag_rounded),
                            title: const Text('Reportes del Foro de Poemas'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                context.push(AppRoutes.adminPoemReports),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: 'Cerrar sesión',
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('¿Cerrar sesión?'),
                          content: const Text(
                            '¿Estás seguro de que deseas cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.welcome);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'moderador':
        return 'Moderador';
      default:
        return 'Usuario';
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PoemStat extends StatelessWidget {
  final String label;
  final String value;
  const _PoemStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

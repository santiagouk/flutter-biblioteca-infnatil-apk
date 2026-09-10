import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/admin_user_service.dart';
import '../../providers/auth_provider.dart';

/// Gestión de usuarios: selector de rol de 3 vías (admin / moderador
/// / usuario), igual que en la versión web.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = AdminUserService();
  List<UserProfileModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar los usuarios: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRole(UserProfileModel user, String newRole) async {
    final myId = context.read<AuthProvider>().userProfile?.id;
    if (user.id == myId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No puedes cambiar tu propio rol desde aquí.')),
      );
      return;
    }
    final previousUsers = List<UserProfileModel>.from(_users);
    setState(() {
      _users = _users
          .map((u) => u.id == user.id ? u.copyWith(rol: newRole) : u)
          .toList();
    });
    try {
      await _service.updateRole(userId: user.id, rol: newRole);
    } catch (e) {
      if (!mounted) return;
      setState(() => _users = previousUsers);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _roleLabel(String rol) {
    switch (rol) {
      case AppConstants.roleAdmin:
        return 'Administrador';
      case AppConstants.roleModerador:
        return 'Moderador';
      default:
        return 'Usuario';
    }
  }

  Color _roleColor(String rol) {
    switch (rol) {
      case AppConstants.roleAdmin:
        return AppColors.error;
      case AppConstants.roleModerador:
        return AppColors.accentOrange;
      default:
        return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator()
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _roleColor(user.rol).withOpacity(0.15),
                              child: Icon(Icons.person_rounded,
                                  color: _roleColor(user.rol)),
                            ),
                            title: Text(user.displayName,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(user.email,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: DropdownButton<String>(
                              value: user.rol,
                              underline: const SizedBox.shrink(),
                              items: const [
                                AppConstants.roleUsuario,
                                AppConstants.roleModerador,
                                AppConstants.roleAdmin,
                              ]
                                  .map((rol) => DropdownMenuItem(
                                        value: rol,
                                        child: Text(_roleLabel(rol)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) _changeRole(user, value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

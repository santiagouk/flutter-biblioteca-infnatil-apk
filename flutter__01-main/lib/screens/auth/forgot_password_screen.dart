import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de recuperación de contraseña: solicita el correo del
/// usuario y le pide a Supabase Auth que envíe el enlace de reinicio.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    if (success) {
      setState(() => _emailSent = true);
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _emailSent ? _buildSuccessState(context) : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final authProvider = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text('¿Olvidaste tu contraseña?',
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            'No te preocupes. Ingresa tu correo y te enviaremos un enlace para crear una nueva contraseña.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              if (!value.contains('@')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Enviar enlace',
            isLoading: authProvider.isLoading,
            onPressed: _handleSendEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_rounded,
            size: 72, color: AppColors.success),
        const SizedBox(height: 16),
        Text('¡Correo enviado!',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Revisa la bandeja de entrada de ${_emailController.text} y sigue el enlace para crear una nueva contraseña.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

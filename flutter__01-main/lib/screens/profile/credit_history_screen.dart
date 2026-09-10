import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credits_provider.dart';

/// Historial de movimientos de créditos del usuario (ganados y
/// gastados), leído de `credit_transactions`.
class CreditHistoryScreen extends StatefulWidget {
  const CreditHistoryScreen({super.key});

  @override
  State<CreditHistoryScreen> createState() => _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends State<CreditHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userProfile?.id;
      if (userId != null) {
        context.read<CreditsProvider>().loadHistory(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<CreditsProvider>();
    final saldo = context.watch<AuthProvider>().userProfile?.creditos ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de créditos')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Saldo actual: $saldo créditos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: credits.isLoadingHistory
                  ? const AppLoadingIndicator()
                  : credits.history.isEmpty
                      ? const AppEmptyState(
                          message: 'Todavía no tienes movimientos de créditos.',
                          icon: Icons.toll_rounded,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: credits.history.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = credits.history[index];
                            return ListTile(
                              leading: Icon(
                                tx.esPositiva
                                    ? Icons.add_circle_outline_rounded
                                    : Icons.remove_circle_outline_rounded,
                                color: tx.esPositiva
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              title: Text(tx.motivo),
                              subtitle: Text(_formatDate(tx.creadoEn)),
                              trailing: Text(
                                '${tx.esPositiva ? '+' : ''}${tx.cantidad}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tx.esPositiva
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

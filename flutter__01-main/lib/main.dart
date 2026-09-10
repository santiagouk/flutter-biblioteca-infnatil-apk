import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_client_service.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/credits_provider.dart';
import 'providers/poems_provider.dart';
import 'providers/reading_activity_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase (Auth + Base de datos + Storage) antes de
  // levantar cualquier pantalla que dependa de sesión o datos.
  await SupabaseClientService.initialize();

  // Necesario para que DateFormat con locale 'es' (usado en el
  // historial de lectura) funcione correctamente.
  await initializeDateFormatting('es');

  runApp(const BibliotecaInfantilApp());
}

/// Widget raíz de la aplicación.
///
/// Registra los providers globales (autenticación, catálogo y tema)
/// por encima del [MaterialApp.router], para que estén disponibles en
/// cualquier pantalla sin necesidad de pasarlos manualmente.
class BibliotecaInfantilApp extends StatelessWidget {
  const BibliotecaInfantilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => ReadingActivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PoemsProvider()),
        ChangeNotifierProvider(create: (_) => CreditsProvider()),
      ],
      child: const _AppWithRouter(),
    );
  }
}

/// Construye [GoRouter] una única vez (usando el [AuthProvider] ya
/// disponible en el árbol) y lo mantiene estable durante todo el
/// ciclo de vida de la app. El propio [GoRouter] se refresca solo
/// gracias a `refreshListenable: authProvider` — no es necesario, ni
/// conveniente, recrearlo en cada rebuild.
class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  late final AppRouter _appRouter =
      AppRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: _appRouter.router,
    );
  }
}

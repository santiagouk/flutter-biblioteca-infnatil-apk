import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsula la inicialización y el acceso al cliente de Supabase.
///
/// Apunta al proyecto real de Supabase `biblioteca infantil`
/// (id `pbkbqggeaquncsmuykec`) — el mismo backend que usa la versión
/// web. La clave usada aquí es la clave pública `anon`: es segura de
/// distribuir dentro de la app porque todo el acceso está limitado
/// por las políticas RLS de cada tabla. Nunca uses la `service_role
/// key` en la app móvil.
class SupabaseClientService {
  SupabaseClientService._();

  static const String supabaseUrl = 'https://pbkbqggeaquncsmuykec.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBia2JxZ2dlYXF1bmNzbXV5a2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NzQ0MjUsImV4cCI6MjA5NzU1MDQyNX0.iD2ln_FhAlRFRw4ReLe_hwj6v2LRFEvm6tXPSTqmWCg';

  /// Debe llamarse una única vez, antes de `runApp()`, típicamente en
  /// `main.dart`.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Acceso directo al cliente ya inicializado, usado por el resto de
  /// los servicios de la capa `data`.
  static SupabaseClient get client => Supabase.instance.client;
}

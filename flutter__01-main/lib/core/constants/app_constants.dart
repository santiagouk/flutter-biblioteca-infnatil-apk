/// Constantes generales de la aplicación.
///
/// Centraliza valores fijos (nombres de tablas, columnas de enums,
/// buckets de almacenamiento, claves de preferencias locales, etc.)
/// para evitar "magic strings" repetidas por todo el proyecto.
///
/// IMPORTANTE: estos nombres corresponden EXACTAMENTE al esquema real
/// del proyecto de Supabase `biblioteca infantil` (id de proyecto
/// `pbkbqggeaquncsmuykec`), verificado directamente contra la base de
/// datos en producción — el mismo backend que usa la versión web.
class AppConstants {
  AppConstants._(); // Evita que la clase sea instanciada.

  // ---------------------------------------------------------------------
  // Información general
  // ---------------------------------------------------------------------
  static const String appName = 'Biblioteca Infantil';
  static const String appTagline = 'Un mundo de historias te espera';

  // ---------------------------------------------------------------------
  // Nombres de tablas en Supabase (PostgreSQL) — esquema real, español
  // ---------------------------------------------------------------------
  static const String tableProfiles = 'profiles';
  static const String tableCategories = 'categories';
  static const String tableBooks = 'books';
  static const String tableFavorites = 'favorites';
  static const String tableReadingHistory = 'reading_history';
  static const String tableBookmarks = 'bookmarks';
  static const String tableBookLikes = 'book_likes';
  static const String tableBookComments = 'book_comments';
  static const String tablePoems = 'poems';
  static const String viewPoemsWithStats = 'poemas_con_estadisticas';
  static const String viewUserPoemStats = 'estadisticas_poemas_usuario';
  static const String tablePoemRatings = 'poem_ratings';
  static const String tablePoemLikes = 'poem_likes';
  static const String tablePoemReports = 'poem_reports';
  static const String tableCreditTransactions = 'credit_transactions';
  static const String tableUnlockedVipBooks = 'unlocked_vip_books';

  // ---------------------------------------------------------------------
  // Funciones RPC
  // ---------------------------------------------------------------------
  // La misma que usa la versión web para "Recomendados" en Inicio
  // (basada en popularidad real: me gusta + lecturas + favoritos, con
  // respaldo a destacados).
  static const String rpcLibrosRecomendados = 'obtener_libros_recomendados';
  // Canjea créditos por el acceso a un libro VIP (valida saldo y
  // registra la transacción/desbloqueo del lado del servidor).
  static const String rpcCanjearLibroVip = 'canjear_libro_vip';

  // ---------------------------------------------------------------------
  // Buckets de Supabase Storage (ambos públicos)
  // ---------------------------------------------------------------------
  static const String bucketCovers = 'portadas';
  static const String bucketFiles = 'libros-pdf';

  // ---------------------------------------------------------------------
  // Roles de usuario (enum `user_role` en la columna `rol` de profiles)
  // ---------------------------------------------------------------------
  static const String roleAdmin = 'admin';
  static const String roleUsuario = 'usuario';
  static const String roleModerador = 'moderador';

  // ---------------------------------------------------------------------
  // Rangos de edad recomendada (enum `rango_edad` en `books.edad_recomendada`)
  // ---------------------------------------------------------------------
  static const List<String> ageRanges = ['3-5', '6-8', '9-12', '13+'];

  // ---------------------------------------------------------------------
  // Claves de SharedPreferences (persistencia local)
  // ---------------------------------------------------------------------
  static const String prefThemeMode = 'pref_theme_mode';

  // ---------------------------------------------------------------------
  // Límites y valores por defecto
  // ---------------------------------------------------------------------
  static const int featuredBooksLimit = 10;
  static const int searchDebounceMillis = 400;
  static const double maxContentWidth = 720; // Límite en tablets/desktop
}

# Biblioteca Infantil Virtual — App Flutter

App móvil (Flutter) para la plataforma de lectura infantil, conectada al
**mismo backend real de Supabase que usa la versión web** (proyecto
`biblioteca infantil`, id `pbkbqggeaquncsmuykec`). Este README documenta
el estado actual del proyecto y cómo ponerlo en marcha.

## Ya está conectado a tu base de datos real

`lib/data/services/supabase_client_service.dart` ya tiene la URL y la
clave pública (`anon`) reales del proyecto — no necesitas configurar nada
para conectarte. El esquema completo (tablas, columnas, enums, triggers y
políticas RLS) se verificó directamente contra la base de datos en
producción, la misma que usa `js/datos.js` en la versión web.

## Estado del proyecto — Fases 1 y 2 entregadas, alineadas al esquema real

✅ Arquitectura completa (carpetas `core`, `data`, `providers`, `screens`,
`widgets`), tema claro/oscuro, routing centralizado con protección de
rutas, modelos de datos y capa de servicios completa contra Supabase.

✅ Pantallas 100% funcionales: Splash, Bienvenida, Login, Registro,
Recuperar contraseña, Home (categorías + libros recomendados vía la
función `obtener_libros_recomendados`, la misma que usa la web), Búsqueda,
Detalle de libro (con edad recomendada y categoría), Lector de PDF con
guardado automático de progreso, Favoritos e Historial de lectura.

🚧 Pantallas con placeholder "Próximamente": Perfil, Configuración, Panel
de administrador.

- **Fase 3:** Perfil, Configuración (switch claro/oscuro, ya implementado
  a nivel de lógica en `ThemeProvider`).
- **Fase 4:** Panel de administrador (CRUD libros/categorías/usuarios,
  subida de portadas/PDF a Storage, estadísticas).

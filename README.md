<p align="center">
  <img src="apps/web/public/logo.png" alt="Neil's Food Services" width="240" />
</p>

# Neil's Food Services

Plataforma de venta y reparto de abarrotes con tres canales conectados a una misma API:

| Canal | Qué hace hoy | Tecnología |
|---|---|---|
| **App Android** (`apps/android`) | Catálogo con búsqueda y categorías, detalle, carrito, registro e inicio de sesión, pedidos y "Mis pedidos" con el estado de cada uno | Kotlin, Jetpack Compose, Retrofit |
| **Tienda web** (`apps/web`) | El mismo flujo de compra desde el navegador: catálogo, carrito y checkout | Next.js 16, Tailwind CSS 4 |
| **Panel admin** (`apps/web`, ruta `/admin`) | Pedidos con filtro y avance de estado, cancelación con devolución de stock, alta y edición de productos | Next.js 16 |
| **API** (`apps/api`) | Autenticación JWT con roles (`CUSTOMER`, `STAFF`, `ADMIN`), productos, categorías y pedidos con control de stock | NestJS, Prisma, PostgreSQL |

Los pedidos siguen siempre los mismos estados: pendiente de confirmación → confirmado → en reparto → entregado (o cancelado).

## Correr la demo

Requisitos: Node.js 20 o superior, PostgreSQL y, para la app, Android Studio Quail 4 o superior.

1. **Base de datos y API**: la primera vez, sigue [`apps/api/README.md`](apps/api/README.md) para crear la base, aplicar las migraciones y cargar los datos de prueba. El seed crea un administrador (`admin@abarrotes.test`) e imprime su contraseña.
2. **Levantar la API y la web**, cada una en su terminal, desde la raíz del repo:

   ```bash
   npm run api:dev
   ```

   ```bash
   npm run web:dev
   ```

   La tienda queda en http://localhost:3000 y el panel en http://localhost:3000/admin. En Windows PowerShell, si aparece "la ejecución de scripts está deshabilitada", escribe `npm.cmd` en vez de `npm`.
3. **App Android**: abre la carpeta `apps/android` en Android Studio y ejecútala en un emulador con Android 17. Los detalles (permiso de red local, IP para un teléfono real) están en [`apps/android/README.md`](apps/android/README.md).

Recorrido sugerido: compra desde la app o la web, confirma o envía el pedido desde `/admin/pedidos` y mira cómo cambia el estado en "Mis pedidos" de la app.

## Estructura

```
apps/android          App del cliente (Kotlin)
apps/web              Tienda web y panel admin (Next.js)
apps/api              API (NestJS)
packages/shared-types Tipos compartidos entre la web y la API
prisma                Modelo de datos, migraciones y datos de prueba
docs                  Arquitectura y hoja de ruta
```

## Documentación

- [Arquitectura y hoja de ruta](docs/ARQUITECTURA_Y_ROADMAP.md): decisiones de diseño y fases del proyecto.
- READMEs de cada parte: [API](apps/api/README.md), [web](apps/web/README.md) (incluye el sistema de diseño de la marca) y [Android](apps/android/README.md).
- [CLAUDE.md](CLAUDE.md): convenciones del repo (commits, ramas, módulos).

## Cómo se trabaja

- Ramas: `main` ← `develop` ← `feature/<nombre>`. A `main` y `develop` solo se llega por pull request; el hook `.githooks/pre-push`, que se activa con `npm install`, bloquea el push directo.
- Cada pull request corre el CI de GitHub Actions: lint, tests y build de la API (con PostgreSQL), la web y la app Android.

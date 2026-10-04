# Servidor Serverpod — Abarrotes

Backend nuevo en Dart con [Serverpod 4](https://docs.serverpod.dev), que irá reemplazando a la
API NestJS de `apps/api`. Mientras conviven, cada uno usa **su propia base** en el mismo
PostgreSQL local: `abarrotes` (Prisma, con los datos de la demo) y `abarrotes_server` (Serverpod).
No compartas la base: Prisma y Serverpod borran las tablas que no reconocen.

## Estructura

```
apps/server/
  pubspec.yaml            -> workspace de Dart (server + client)
  abarrotes_server/       -> el servidor
    bin/main.dart
    config/               -> development / test / staging / production (+ passwords.yaml, no versionado)
    lib/server.dart       -> arma el pod
    lib/src/<dominio>/    -> modelos (.spy.yaml) y código de cada dominio
    lib/src/generated/    -> lo escribe `serverpod generate`: no se edita a mano
    migrations/           -> migraciones generadas, se versionan
    test/
  abarrotes_client/       -> cliente Dart generado (lo exige el generador; Android y web no lo usan)
```

Un dominio por carpeta (`users`, `categories`, `products`, `inventory`, `supplies`, `orders`,
`promotions`): ningún dominio importa la lógica de otro.

## Requisitos

- **Dart SDK ≥ 3.12** (probado con 3.13.5). En Windows: descomprimir el zip oficial de
  [dart.dev](https://dart.dev/get-dart/archive) en `%LOCALAPPDATA%\dart-sdk` y agregar al `Path`
  del usuario `%LOCALAPPDATA%\dart-sdk\bin` y `%LOCALAPPDATA%\Pub\Cache\bin`.
- **CLI de Serverpod**, misma versión que el paquete:

  ```powershell
  dart pub global activate serverpod_cli 4.0.3
  ```

  La CLI exige Flutter salvo en CI. Este proyecto es solo de servidor y no lo necesita: antes de
  usar `serverpod` en una terminal, marca la sesión como CI.

  ```powershell
  $env:CI = 'true'
  ```

- **PostgreSQL** local (el mismo que usa `apps/api`). El usuario `abarrotes` necesita permiso
  `CREATEDB`: los tests crean y borran bases temporales.

## Primera vez

1. Crear la base del servidor (con el usuario `abarrotes`, no hace falta superusuario):

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U abarrotes -d abarrotes -c "CREATE DATABASE abarrotes_server"
   ```

2. Crear `abarrotes_server/config/passwords.yaml` (está en `.gitignore`):

   ```yaml
   shared:
     # Proyecto de Firebase cuyos ID tokens acepta el servidor (no es secreto).
     firebaseProjectId: '<project id de Firebase>'
   development:
     database: '<contraseña del usuario abarrotes>'
     serviceSecret: '<cadena aleatoria larga>'
   test:
     database: '<contraseña del usuario abarrotes>'
   ```

   En CI o en un servidor, las mismas claves llegan por variables de entorno:
   `SERVERPOD_PASSWORD_database`, `SERVERPOD_PASSWORD_serviceSecret`, etc. El project id
   también puede venir de `FIREBASE_PROJECT_ID`. Sin él, el servidor no arranca.

3. Dependencias y migraciones, desde `apps/server/abarrotes_server`:

   ```powershell
   dart pub get
   dart run bin/main.dart --role maintenance --apply-migrations
   ```

## Día a día (desde `apps/server/abarrotes_server`)

| Qué | Comando |
|---|---|
| Levantar el servidor (API 8088, Insights 8081, web 8082) | `dart run bin/main.dart` |
| Regenerar código tras editar un `.spy.yaml` | `serverpod generate` |
| Crear la migración de ese cambio (se commitea) | `serverpod create-migration` |
| Aplicar migraciones pendientes | `dart run bin/main.dart --role maintenance --apply-migrations` |
| Análisis estático | `dart analyze` |
| Tests (unitarios + integración con PostgreSQL) | `dart test` |

## Autenticación con Firebase

Las cuentas viven en **Firebase Auth**: el servidor no guarda contraseñas. Cada petición
protegida trae el ID token de Firebase en `Authorization: Bearer <token>`, y el servidor:

- Verifica la firma RS256 con las llaves públicas de Google
  (`securetoken@system.gserviceaccount.com`). Las cachea según su `Cache-Control` y las vuelve a
  descargar si Google las rota.
- Exige `iss = https://securetoken.google.com/<project id>`, `aud = <project id>`, el token
  vigente y un `sub` (el uid) no vacío.
- Busca al usuario por `firebaseUid` en `users`. Ahí viven el **rol** y los datos de la tienda.

Código en `lib/src/auth/`: `GooglePublicKeys` (llaves), `FirebaseTokenVerifier`,
`firebaseAuthMiddleware` (rutas REST) y `firebaseAuthenticationHandler`. Este último autentica
también la sesión de Serverpod con el uid, para los endpoints que se agreguen después.

## Endpoints (servidor web, puerto 8082)

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /users/me` | cualquiera con token | Devuelve el usuario del token. La primera vez lo crea como `customer` con el email y el nombre de Firebase. |
| `POST /users` | solo `admin` | Crea una cuenta `admin` o `staff` vinculada a un `firebaseUid` existente. Es la única forma de tener esos roles. |

Respuesta de ambos: `{id, email, name, phone, role, address, createdAt}`, con `role` igual a
`customer`, `admin` o `staff`. Body de `POST /users`:
`{firebaseUid, email, name, role, phone?, address?}`.

Errores con la forma de la API NestJS (`{statusCode, message, error}`):

- 401: sin token o con uno inválido.
- 403: quien llama no es admin.
- 400: body inválido, o token sin email en `/users/me`.
- 409: `firebaseUid` o email ya registrados.
- 503: no se pudieron obtener las llaves de Google.

### Primer admin

`POST /users` exige un admin, así que el primero se crea a mano:

1. La persona inicia sesión una vez en la app o la web; `GET /users/me` la crea como cliente.
2. Se le cambia el rol en la base:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U abarrotes -d abarrotes_server -c "UPDATE users SET role = 'admin' WHERE email = 'correo@ejemplo.com'"
   ```

### Probar con un token real

Desde la app o la web ya logueadas con Firebase, `await user.getIdToken()` entrega el token
(dura una hora). Con él:

```powershell
curl.exe -H "Authorization: Bearer <token>" http://localhost:8082/users/me
```

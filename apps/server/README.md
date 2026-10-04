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
   development:
     database: '<contraseña del usuario abarrotes>'
     serviceSecret: '<cadena aleatoria larga>'
   test:
     database: '<contraseña del usuario abarrotes>'
   ```

   En CI o en un servidor, las mismas claves llegan por variables de entorno:
   `SERVERPOD_PASSWORD_database`, `SERVERPOD_PASSWORD_serviceSecret`, etc.

3. Dependencias y migraciones, desde `apps/server/abarrotes_server`:

   ```powershell
   dart pub get
   dart run bin/main.dart --role maintenance --apply-migrations
   ```

## Día a día (desde `apps/server/abarrotes_server`)

| Qué | Comando |
|---|---|
| Levantar el servidor (API 8080, Insights 8081, web 8082) | `dart run bin/main.dart` |
| Regenerar código tras editar un `.spy.yaml` | `serverpod generate` |
| Crear la migración de ese cambio (se commitea) | `serverpod create-migration` |
| Aplicar migraciones pendientes | `dart run bin/main.dart --role maintenance --apply-migrations` |
| Análisis estático | `dart analyze` |
| Tests | `dart test` |

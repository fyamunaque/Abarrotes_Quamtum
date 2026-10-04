import 'dart:io';

import 'src/auth/firebase_authentication_handler.dart';
import 'src/auth/firebase_token_verifier.dart';
import 'src/auth/google_public_keys.dart';
import 'src/categories/categories_routes.dart';
import 'src/categories/categories_service.dart';
import 'src/common/api_route.dart';
import 'src/generated/serverpod.dart';
import 'src/inventory/inventory_routes.dart';
import 'src/inventory/inventory_service.dart';
import 'src/inventory/stock_alerts.dart';
import 'src/orders/orders_routes.dart';
import 'src/orders/orders_service.dart';
import 'src/products/products_routes.dart';
import 'src/products/products_service.dart';
import 'src/promotions/promotions_routes.dart';
import 'src/promotions/promotions_service.dart';
import 'src/users/users_routes.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // El project id sale de passwords.yaml, que el pod carga al crearse; el
  // handler de autenticación lo usa recién con la primera petición.
  late final FirebaseTokenVerifier verifier;

  // Serverpod ya trae configurados el Protocol y los Endpoints generados.
  final pod = Serverpod(
    args,
    authenticationHandler: (session, token) =>
        firebaseAuthenticationHandler(verifier)(session, token),
  );

  verifier = FirebaseTokenVerifier(
    projectId: _firebaseProjectId(pod),
    keys: GooglePublicKeys(),
  );

  // Un dominio por bloque de rutas.
  addUsersRoutes(pod.webServer, verifier: verifier);
  addRoutes(pod.webServer, [
    ...categoriesRoutes(const CategoriesService(), verifier),
    ...productsRoutes(ProductsService(), verifier),
    ...promotionsRoutes(PromotionsService(), verifier),
    ...inventoryRoutes(const InventoryService(), StockAlerts(), verifier),
    ...ordersRoutes(OrdersService(), verifier),
  ]);

  await pod.start();
}

/// El proyecto de Firebase cuyos ID tokens se aceptan: `firebaseProjectId` en
/// config/passwords.yaml o la variable de entorno FIREBASE_PROJECT_ID.
String _firebaseProjectId(Serverpod pod) {
  final projectId =
      pod.getPassword('firebaseProjectId') ??
      Platform.environment['FIREBASE_PROJECT_ID'];
  if (projectId == null || projectId.trim().isEmpty) {
    throw StateError(
      'Falta el project id de Firebase: agrega firebaseProjectId en '
      'config/passwords.yaml o define FIREBASE_PROJECT_ID.',
    );
  }
  return projectId.trim();
}

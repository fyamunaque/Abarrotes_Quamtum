import 'dart:convert';
import 'dart:io';

import 'src/auth/firebase_authentication_handler.dart';
import 'src/auth/firebase_token_verifier.dart';
import 'src/auth/google_public_keys.dart';
import 'src/categories/categories_routes.dart';
import 'src/categories/categories_service.dart';
import 'src/common/api_route.dart';
import 'src/common/cors.dart';
import 'src/generated/serverpod.dart';
import 'src/inventory/inventory_routes.dart';
import 'src/inventory/inventory_service.dart';
import 'src/inventory/stock_alerts.dart';
import 'src/orders/orders_routes.dart';
import 'src/orders/orders_service.dart';
import 'src/products/products_routes.dart';
import 'src/products/products_service.dart';
import 'src/promotions/audience/everyone_audience_rule.dart';
import 'src/promotions/audience/vip_audience_rule.dart';
import 'src/promotions/promotions_routes.dart';
import 'src/promotions/promotions_service.dart';
import 'src/push/fcm_push_sender.dart';
import 'src/push/google_access_tokens.dart';
import 'src/push/push_sender.dart';
import 'src/stats/providers/expiring_products_report_provider.dart';
import 'src/stats/providers/low_stock_report_provider.dart';
import 'src/stats/providers/order_status_report_provider.dart';
import 'src/stats/providers/overview_report_provider.dart';
import 'src/stats/providers/sales_report_provider.dart';
import 'src/stats/providers/top_products_report_provider.dart';
import 'src/stats/stats_routes.dart';
import 'src/users/users_routes.dart';
import 'src/vip/vip_promotion_announcer.dart';
import 'src/vip/vip_routes.dart';
import 'src/vip/vip_service.dart';
import 'src/vip/vip_shopper_resolver.dart';

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

  final projectId = _firebaseProjectId(pod);
  verifier = FirebaseTokenVerifier(
    projectId: projectId,
    keys: GooglePublicKeys(),
  );

  final stockAlerts = StockAlerts();
  const sales = SalesReportProvider();

  // Quién es cada cliente (VIP o no) y qué audiencias de promociones puede
  // usar. Un segmento nuevo es una regla más en esta lista.
  const vips = VipService();
  const shoppers = VipShopperResolver(vips);
  final promotions = PromotionsService(
    audienceRules: const [EveryoneAudienceRule(), VipAudienceRule()],
    // Una promoción VIP que ya rige se avisa por push a los VIP.
    announcer: VipPromotionAnnouncer(
      sender: _pushSender(pod, projectId),
      run: pod.withSession,
      vips: vips,
    ),
  );

  // CORS para la app Flutter web, que corre en otro origen. En `/` envuelve a
  // los middlewares de cada dominio (p. ej. el de Firebase en `/users`).
  pod.webServer.addMiddleware(
    corsMiddleware(
      allowedOrigins(
        development: pod.runMode == 'development',
        extra: (Platform.environment['ALLOWED_ORIGINS'] ?? '').split(','),
      ),
    ),
    '/',
  );

  // Un dominio por bloque de rutas.
  addUsersRoutes(pod.webServer, verifier: verifier, shoppers: shoppers);
  addRoutes(pod.webServer, [
    ...categoriesRoutes(const CategoriesService(), verifier),
    ...productsRoutes(
      ProductsService(pricing: promotions),
      verifier,
      shoppers: shoppers,
    ),
    ...promotionsRoutes(promotions, verifier, shoppers: shoppers),
    ...inventoryRoutes(const InventoryService(), stockAlerts, verifier),
    ...ordersRoutes(
      OrdersService(pricing: promotions),
      verifier,
      shoppers: shoppers,
    ),
    ...vipRoutes(vips, verifier),
    // Cada reporte se inyecta por separado: cambiar una estrategia es cambiar
    // la clase que se pasa aquí.
    ...statsRoutes(
      overview: OverviewReportProvider(
        sales: sales,
        orderStatus: const OrderStatusReportProvider(),
      ),
      sales: sales,
      topProducts: const TopProductsReportProvider(),
      lowStock: LowStockReportProvider(stockAlerts),
      expiring: ExpiringProductsReportProvider(stockAlerts),
      verifier: verifier,
    ),
  ]);

  await pod.start();
}

/// El envío push con FCM, si hay una cuenta de servicio configurada:
/// `fcmServiceAccountFile` en config/passwords.yaml (o la variable
/// FCM_SERVICE_ACCOUNT_FILE) con la ruta de su JSON. Sin eso, o si no se
/// puede leer, el servidor arranca igual, sin avisos push. El contenido del
/// archivo es un secreto: nunca va al log.
PushSender _pushSender(Serverpod pod, String firebaseProjectId) {
  final path =
      (pod.getPassword('fcmServiceAccountFile') ??
              Platform.environment['FCM_SERVICE_ACCOUNT_FILE'])
          ?.trim();
  if (path == null || path.isEmpty) {
    stdout.writeln(
      'Aviso push desactivado: falta fcmServiceAccountFile en '
      'config/passwords.yaml (o FCM_SERVICE_ACCOUNT_FILE).',
    );
    return const DisabledPushSender();
  }
  final ServiceAccount account;
  try {
    account = ServiceAccount.fromJson(
      jsonDecode(File(path).readAsStringSync()),
    );
  } on Object catch (e) {
    stderr.writeln(
      'Aviso push desactivado: no se pudo leer la cuenta de servicio de '
      '$path (${e.runtimeType}).',
    );
    return const DisabledPushSender();
  }
  if (account.projectId != firebaseProjectId) {
    stderr.writeln(
      'Atención: la cuenta de servicio es del proyecto ${account.projectId} '
      'y los ID tokens, de $firebaseProjectId.',
    );
  }
  return FcmPushSender(
    projectId: account.projectId,
    accessTokens: GoogleAccessTokens(account, scope: FcmPushSender.scope),
  );
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

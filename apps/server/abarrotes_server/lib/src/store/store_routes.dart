import 'package:serverpod/serverpod.dart';

import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../generated/protocol.dart';
import 'store_settings_service.dart';

/// Los datos de la tienda: lectura pública (el cliente los ve al elegir
/// recojo) y edición con `store.manage`.
List<RouteEntry> storeRoutes(StoreSettingsService store, Guards guards) => [
  (
    '/store',
    ApiRoute(Method.get, (session, request) async {
      InputReader.query(request, allowed: const {}).check();
      return jsonResponse(200, storeSettingsJson(await store.get(session)));
    }),
  ),
  (
    '/store',
    // Campos parciales; null borra los opcionales.
    guards.require(
      Permission.storeManage,
      ApiRoute(Method.patch, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {
            'name',
            'address',
            'reference',
            'phone',
            'openingHours',
            'pickupInstructions',
          },
        );
        final name = body.text('name', maxLength: 100, required: false);
        final address = body.text('address', maxLength: 255, required: false);
        final reference = body.text(
          'reference',
          maxLength: 255,
          nullable: true,
        );
        final phone = body.text('phone', maxLength: 30, nullable: true);
        final openingHours = body.text(
          'openingHours',
          maxLength: 500,
          nullable: true,
        );
        final pickupInstructions = body.text(
          'pickupInstructions',
          maxLength: 500,
          nullable: true,
        );
        body.check();

        final saved = await store.update(session, (current) {
          var settings = current.copyWith(name: name, address: address);
          if (body.has('reference')) {
            settings = settings.copyWith(reference: reference);
          }
          if (body.has('phone')) settings = settings.copyWith(phone: phone);
          if (body.has('openingHours')) {
            settings = settings.copyWith(openingHours: openingHours);
          }
          if (body.has('pickupInstructions')) {
            settings = settings.copyWith(
              pickupInstructions: pickupInstructions,
            );
          }
          return settings;
        }, by: request.currentUser);
        return jsonResponse(200, storeSettingsJson(saved));
      }),
    ),
  ),
];

/// Los datos de la tienda como los lee la app. `updatedAt` va en null
/// mientras nadie los cargó.
Map<String, Object?> storeSettingsJson(StoreSettings settings) => {
  'name': settings.name,
  'address': settings.address,
  'reference': settings.reference,
  'phone': settings.phone,
  'openingHours': settings.openingHours,
  'pickupInstructions': settings.pickupInstructions,
  'updatedAt': settings.id == null
      ? null
      : settings.updatedAt.toUtc().toIso8601String(),
};

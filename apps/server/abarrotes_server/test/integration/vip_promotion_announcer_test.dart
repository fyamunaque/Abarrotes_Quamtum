import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotion_rules.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:abarrotes_server/src/push/push_sender.dart';
import 'package:abarrotes_server/src/vip/vip_promotion_announcer.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_push.dart';
import '../support/http_harness.dart';
import '../support/staff_setup.dart';
import '../support/promotions_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  final today = storeDay(testNow);
  String day(int offset) => addDays(today, offset);

  withServerpod('Aviso push de las promociones VIP', (sessionBuilder, _) {
    late Session session;
    late FakePushSender push;
    late Promotion promotion;
    late User admin;

    /// Un cliente con su correo (verificado o no) y sus dispositivos.
    Future<User> customer(
      String uid, {
      required bool verified,
      List<String> devices = const [],
    }) async {
      final user = await User.db.updateRow(
        session,
        (await insertUser(session, uid)).copyWith(emailVerified: verified),
      );
      for (final token in devices) {
        await DeviceToken.db.insertRow(
          session,
          DeviceToken(token: token, userId: user.id!),
        );
      }
      return user;
    }

    VipPromotionAnnouncer announcer({void Function()? onRun}) =>
        VipPromotionAnnouncer(
          sender: push,
          run: (work) async {
            onRun?.call();
            await work(session);
          },
        );

    setUp(() async {
      session = sessionBuilder.build();
      push = FakePushSender();
      admin = await insertStaff(session, 'uid-admin');
      final category = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      final arroz = await Product.db.insertRow(
        session,
        Product(
          name: 'Arroz extra 5 kg',
          sku: 'ARROZ-5',
          priceCents: 2490,
          categoryId: category.id!,
        ),
      );
      final period = toStoredPeriod(day(0), day(14));
      final created = await Promotion.db.insertRow(
        session,
        Promotion(
          productId: arroz.id!,
          promoPriceCents: 1790,
          startDate: period.startDate,
          endDate: period.endDate,
          audience: PromotionAudience.vip,
          title: 'Semana VIP',
        ),
      );
      promotion = (await Promotion.db.findById(
        session,
        created.id!,
        include: Promotion.include(product: Product.include()),
      ))!;

      // Ana: VIP con el correo verificado, en el teléfono y en la web.
      await customer(
        'uid-ana',
        verified: true,
        devices: ['ana-telefono', 'ana-web'],
      );
      // Luis: VIP sin verificar. Carla: verificada, pero no es VIP. Beto:
      // VIP dado de baja.
      await customer('uid-luis', verified: false, devices: ['luis-telefono']);
      await customer('uid-carla', verified: true, devices: ['carla-web']);
      await customer('uid-beto', verified: true, devices: ['beto-telefono']);
      await insertVips(session, admin, [
        'uid-ana@tienda.pe',
        'uid-luis@tienda.pe',
        'uid-beto@tienda.pe',
      ]);
      await VipCustomer.db.updateWhere(
        session,
        columnValues: (vip) => [vip.active(false)],
        where: (vip) => vip.email.equals('uid-beto@tienda.pe'),
      );
    });

    test(
      'llega a cada dispositivo de los VIP activos con el correo verificado',
      () async {
        final summary = await announcer().announceNow(session, promotion);

        expect(summary, (sent: 2, invalid: 0, failed: 0));
        expect(
          {for (final (token, _) in push.sent) token},
          {
            'ana-telefono',
            'ana-web',
          },
        );
        final (_, message) = push.sent.first;
        expect(message.title, 'Nueva oferta exclusiva');
        expect(
          message.body,
          'Semana VIP: Arroz extra 5 kg a S/ 17.90 (antes S/ 24.90), '
          'hasta el 15 oct.',
        );
        expect(message.data, {
          'type': 'vip_promotion',
          'promotionId': promotion.id.toString(),
          'productId': promotion.productId.toString(),
        });
      },
    );

    test(
      'borra los tokens inválidos y, si uno falla, sigue con los demás',
      () async {
        await customer('uid-dora', verified: true, devices: ['dora-telefono']);
        await insertVips(session, admin, ['uid-dora@tienda.pe']);
        push
          ..invalid.add('ana-telefono')
          ..failing.add('ana-web');

        final summary = await announcer().announceNow(session, promotion);

        expect(summary, (sent: 1, invalid: 1, failed: 1));
        final left = {
          for (final device in await DeviceToken.db.find(session)) device.token,
        };
        expect(left, isNot(contains('ana-telefono')));
        expect(left, containsAll(['ana-web', 'dora-telefono']));
      },
    );

    test('sin push configurado no manda nada', () async {
      push = FakePushSender(enabled: false);

      final summary = await announcer().announceNow(session, promotion);

      expect(summary, (sent: 0, invalid: 0, failed: 0));
      expect(push.sent, isEmpty);
    });

    test('announce solo corre para las promociones VIP', () async {
      var runs = 0;
      final vipAnnouncer = announcer(onRun: () => runs++);

      vipAnnouncer.announce(
        promotion.copyWith(audience: PromotionAudience.everyone),
      );
      await Future<void>.delayed(Duration.zero);
      expect(runs, 0);

      vipAnnouncer.announce(promotion);
      // Corre aparte: announce no espera.
      expect(push.sent, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(runs, 1);
      expect(push.sent, hasLength(2));
    });
  });

  withServerpod('Aviso que falla', (sessionBuilder, _) {
    test('si el aviso falla, la promoción se crea igual', () async {
      final session = sessionBuilder.build();
      await insertStaff(session, 'uid-staff');
      final category = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      final arroz = await Product.db.insertRow(
        session,
        Product(
          name: 'Arroz',
          sku: 'ARROZ-1',
          priceCents: 450,
          categoryId: category.id!,
        ),
      );
      final google = generateRsaKeyPair();
      final server = await serveRoutes(
        () => session,
        promotionsRoutes(
          testPromotions(announcer: ThrowingAnnouncer()),
          testGuards(google),
          shoppers: testShoppers,
        ),
      );
      addTearDown(server.close);

      final (status, _) = await TestClient(server, google).post(
        '/promotions',
        {
          'productId': arroz.id.toString(),
          'promoPrice': 3.9,
          'startDate': day(0),
          'endDate': day(6),
          'audience': 'vip',
        },
        as: 'uid-staff',
      );

      expect(status, 201);
      expect(await Promotion.db.count(session), 1);
    });
  });

  test('PushResult y tokenHint no exponen el token', () {
    expect(tokenHint('fcm-token-largo-123456'), '…123456');
  });
}

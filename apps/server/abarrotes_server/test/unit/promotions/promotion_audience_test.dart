import 'package:abarrotes_server/src/common/shopper.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/audience/everyone_audience_rule.dart';
import 'package:abarrotes_server/src/promotions/audience/promotion_audience_rule.dart';
import 'package:abarrotes_server/src/promotions/audience/vip_audience_rule.dart';
import 'package:abarrotes_server/src/promotions/promotions_service.dart';
import 'package:test/test.dart';

void main() {
  const vip = Shopper(email: 'vip@tienda.pe', emailVerified: true, isVip: true);
  const customer = Shopper(email: 'ana@tienda.pe', emailVerified: true);

  group('reglas de audiencia', () {
    test('EveryoneAudienceRule acepta a todos, también sin cuenta', () {
      const rule = EveryoneAudienceRule();

      expect(rule.audience, PromotionAudience.everyone);
      expect(rule.isEligible(Shopper.anonymous), isTrue);
      expect(rule.isEligible(customer), isTrue);
      expect(rule.isEligible(vip), isTrue);
    });

    test('VipAudienceRule solo acepta VIPs', () {
      const rule = VipAudienceRule();

      expect(rule.audience, PromotionAudience.vip);
      expect(rule.isEligible(Shopper.anonymous), isFalse);
      expect(rule.isEligible(customer), isFalse);
      expect(rule.isEligible(vip), isTrue);
    });
  });

  group('PromotionsService.audiencesFor', () {
    test('junta las audiencias de las reglas que el cliente cumple', () {
      final promotions = PromotionsService(
        audienceRules: const [EveryoneAudienceRule(), VipAudienceRule()],
      );

      expect(promotions.audiencesFor(Shopper.anonymous), {
        PromotionAudience.everyone,
      });
      expect(promotions.audiencesFor(vip), {
        PromotionAudience.everyone,
        PromotionAudience.vip,
      });
    });

    test('una audiencia sin regla no la usa nadie', () {
      final promotions = PromotionsService(
        audienceRules: const [EveryoneAudienceRule()],
      );

      expect(promotions.audiencesFor(vip), {PromotionAudience.everyone});
    });

    test('una regla nueva se suma sin tocar el servicio', () {
      // Otro criterio para la misma audiencia: los correos de la tienda.
      final promotions = PromotionsService(
        audienceRules: const [
          EveryoneAudienceRule(),
          VipAudienceRule(),
          _EmailDomainRule(PromotionAudience.vip, '@tienda.pe'),
        ],
      );

      expect(promotions.audiencesFor(customer), {
        PromotionAudience.everyone,
        PromotionAudience.vip,
      });
      expect(promotions.audiencesFor(Shopper.anonymous), {
        PromotionAudience.everyone,
      });
    });
  });
}

/// Una regla de prueba: los correos verificados de un dominio.
class _EmailDomainRule implements PromotionAudienceRule {
  const _EmailDomainRule(this.audience, this.domain);

  @override
  final PromotionAudience audience;
  final String domain;

  @override
  bool isEligible(Shopper shopper) =>
      shopper.emailVerified && (shopper.email?.endsWith(domain) ?? false);
}

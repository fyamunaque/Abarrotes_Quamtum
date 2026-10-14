import '../../generated/protocol.dart';
import 'fulfillment_flow.dart';

/// A domicilio, como todos los pedidos de antes: la tienda lo confirma, sale
/// a reparto y se entrega.
class DeliveryFlow extends FulfillmentFlow {
  const DeliveryFlow();

  @override
  FulfillmentType get type => FulfillmentType.delivery;

  @override
  String get description => 'a domicilio';

  @override
  String get otherStepsNote => 'eso es solo para recojo en tienda';

  @override
  List<OrderStatus> get steps => const [
    OrderStatus.pendingConfirmation,
    OrderStatus.confirmed,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];
}

import { OrderStatus } from '@prisma/client';
import { orderStateOf } from '.';

const {
  PENDING_CONFIRMATION,
  CONFIRMED,
  OUT_FOR_DELIVERY,
  DELIVERED,
  CANCELLED,
} = OrderStatus;

/** El flujo completo: de cada estado, a cuáles se puede pasar. */
const EXPECTED: Record<OrderStatus, OrderStatus[]> = {
  PENDING_CONFIRMATION: [CONFIRMED, CANCELLED],
  CONFIRMED: [OUT_FOR_DELIVERY, CANCELLED],
  OUT_FOR_DELIVERY: [DELIVERED, CANCELLED],
  DELIVERED: [],
  CANCELLED: [],
};

describe('estados del pedido (patrón State)', () => {
  it('cada estado tiene su handler', () => {
    for (const status of Object.values(OrderStatus)) {
      expect(orderStateOf(status).status).toBe(status);
    }
  });

  // Recorre las 25 combinaciones: lo que no está en EXPECTED tiene que rechazarse.
  for (const from of Object.values(OrderStatus)) {
    for (const to of Object.values(OrderStatus)) {
      const allowed = EXPECTED[from].includes(to);
      it(`${from} → ${to}: ${allowed ? 'permitido' : 'rechazado'}`, () => {
        expect(orderStateOf(from).canTransitionTo(to)).toBe(allowed);
      });
    }
  }

  it('explica el rechazo con los estados a los que sí puede pasar', () => {
    expect(orderStateOf(OUT_FOR_DELIVERY).rejectionReason(CONFIRMED)).toBe(
      'Un pedido en camino no puede pasar a confirmado: solo puede pasar a entregado o cancelado',
    );
  });

  it('en los estados finales dice que ya no puede cambiar', () => {
    expect(orderStateOf(DELIVERED).rejectionReason(CANCELLED)).toBe(
      'Un pedido entregado ya no puede cambiar de estado',
    );
    expect(orderStateOf(CANCELLED).rejectionReason(PENDING_CONFIRMATION)).toBe(
      'Un pedido cancelado ya no puede cambiar de estado',
    );
  });

  it('si se pide el mismo estado, avisa que ya está en él', () => {
    expect(
      orderStateOf(PENDING_CONFIRMATION).rejectionReason(PENDING_CONFIRMATION),
    ).toBe('El pedido ya está pendiente de confirmación');
  });
});

import { Global, Module } from '@nestjs/common';

/** Fuente de la hora actual: inyectable para poder fijarla en los tests. */
export interface Clock {
  now(): Date;
}

/** Token de inyección: `@Inject(CLOCK) clock: Clock`. */
export const CLOCK = Symbol('CLOCK');

export const systemClock: Clock = { now: () => new Date() };

/** Reloj del sistema para toda la API (stats, promociones, precios de productos y pedidos). */
@Global()
@Module({
  providers: [{ provide: CLOCK, useValue: systemClock }],
  exports: [CLOCK],
})
export class ClockModule {}

import { describe, expect, it } from 'vitest';
import { replayAnimation } from './motion';

/** Elemento mínimo: registra en orden las operaciones sobre classList y las lecturas de layout. */
function fakeElement(initial: string[] = []) {
  const classes = new Set(initial);
  const log: string[] = [];
  const element = {
    classList: {
      remove: (name: string) => {
        log.push(`remove ${name}`);
        classes.delete(name);
      },
      add: (name: string) => {
        log.push(`add ${name}`);
        classes.add(name);
      },
    },
    get offsetWidth() {
      log.push('reflow');
      return 0;
    },
  };
  return { element: element as unknown as HTMLElement, classes, log };
}

describe('replayAnimation', () => {
  it('quita la clase, fuerza el recálculo y la vuelve a poner para reiniciar la animación', () => {
    const { element, classes, log } = fakeElement(['inline-flex', 'animate-press-bounce']);

    replayAnimation(element, 'animate-press-bounce');

    expect(log).toEqual(['remove animate-press-bounce', 'reflow', 'add animate-press-bounce']);
    expect(classes).toEqual(new Set(['inline-flex', 'animate-press-bounce']));
  });

  it('funciona aunque el elemento todavía no tenga la clase', () => {
    const { element, classes } = fakeElement(['relative']);

    replayAnimation(element, 'animate-cart-pulse');

    expect(classes.has('animate-cart-pulse')).toBe(true);
  });

  it('no hace nada si el ref todavía no apunta a un elemento', () => {
    expect(() => replayAnimation(null, 'animate-cart-pulse')).not.toThrow();
  });
});

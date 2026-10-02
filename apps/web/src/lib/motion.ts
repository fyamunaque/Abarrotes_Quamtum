/**
 * Vuelve a correr una animación CSS de una sola pasada (p. ej. 'animate-press-bounce')
 * sobre un elemento que ya está en pantalla. Las animaciones viven en globals.css; el
 * elemento debe tener también `motion-reduce:animate-none` para respetar
 * prefers-reduced-motion. No cambia el árbol de React, así que no se pierde el foco.
 */
export function replayAnimation(element: HTMLElement | null, animationClass: string): void {
  if (!element) return;
  element.classList.remove(animationClass);
  // Leer el layout obliga al navegador a aplicar la remoción antes de volver a agregarla.
  void element.offsetWidth;
  element.classList.add(animationClass);
}

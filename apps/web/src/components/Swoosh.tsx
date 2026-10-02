/** Forma de pincel del logo: fina a la izquierda, sube hacia la derecha y termina gruesa. */
const SHAPE =
  'M2 29C140 25 300 13 468 3C476 2.4 481 6.5 477 10.5C430 15.5 330 19 230 23C140 26.5 60 29.5 2 29Z';
/** Recorre el centro de SHAPE: es el trazo que la descubre cuando se anima. */
const CENTERLINE = 'M2 29C150 26.5 320 18 474 7';
const MASK_ID = 'swoosh-trazo';

interface SwooshProps {
  className?: string;
  /**
   * Se dibuja de izquierda a derecha al montarse (animate-draw-swoosh). Usa un id fijo,
   * así que solo puede haber uno animado por página (el del hero).
   */
  draw?: boolean;
  /** Se estira al alto y ancho que le den, en vez de conservar la proporción (precios). */
  stretch?: boolean;
}

/** El trazo granate del logo de Neil's (color accent), redibujado en SVG. */
export function Swoosh({ className = '', draw = false, stretch = false }: SwooshProps) {
  return (
    <svg
      viewBox="0 0 480 32"
      preserveAspectRatio={stretch ? 'none' : undefined}
      aria-hidden="true"
      focusable="false"
      // w-0 + min-w-full: toma el ancho del contenedor sin ensancharlo (un SVG con viewBox
      // aporta su propio ancho intrínseco, y el trazo quedaría más largo que el texto).
      className={`block w-0 min-w-full overflow-visible ${stretch ? '' : 'h-auto'} ${className}`}
    >
      {draw && (
        <defs>
          {/* Es una forma rellena, no un trazo: se descubre con una máscara cuyo trazo
              anima el stroke-dashoffset (ver animate-draw-swoosh en globals.css). */}
          <mask id={MASK_ID} maskUnits="userSpaceOnUse" x="-10" y="-10" width="500" height="52">
            <path
              d={CENTERLINE}
              fill="none"
              stroke="white"
              strokeWidth={18}
              strokeLinecap="round"
              pathLength={1}
              strokeDasharray="1 2"
              className="animate-draw-swoosh motion-reduce:animate-none"
            />
          </mask>
        </defs>
      )}
      <path d={SHAPE} mask={draw ? `url(#${MASK_ID})` : undefined} className="fill-accent" />
    </svg>
  );
}

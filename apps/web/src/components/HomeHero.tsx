import Image from 'next/image';

/**
 * Hero de la página principal. Su única animación es el swoosh bajo el titular
 * (animate-draw-swoosh, en globals.css); el resto de la página aparece sin transiciones.
 * Al filtrar o buscar, Next.js conserva la página montada, así que el trazo no se repite.
 */
export function HomeHero() {
  return (
    <section className="grid items-center gap-8 py-2 sm:grid-cols-[1fr_auto] sm:py-6">
      <div className="flex flex-col gap-4">
        {/* w-fit: el swoosh mide lo mismo que la línea más larga del titular. */}
        <div className="w-fit">
          <h1 className="text-4xl leading-[1.05] font-extrabold sm:text-5xl lg:text-6xl">
            Tus abarrotes,
            <br />
            directo a tu casa
          </h1>
          <Swoosh className="mt-0.5 w-full" />
        </div>
        <p className="max-w-md text-lg text-ink/80">
          Elige tus productos y haz tu pedido en línea. La tienda lo confirma antes de enviarlo.
        </p>
      </div>
      {/* En el celular no se muestra: el mismo logo está justo encima, en la cabecera. */}
      <Image
        src="/logo.png"
        alt=""
        width={622}
        height={342}
        sizes="(min-width: 1024px) 320px, 256px"
        className="hidden w-64 rounded-2xl sm:block lg:w-80"
      />
    </section>
  );
}

/**
 * El trazo granate del logo, redibujado en SVG: fino a la izquierda, sube hacia la derecha
 * y termina grueso y redondeado. Como es una forma rellena (no un trazo de grosor fijo), se
 * descubre con una máscara cuyo trazo recorre el centro de la forma y anima su dashoffset.
 */
function Swoosh({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 480 32"
      aria-hidden="true"
      focusable="false"
      className={`block h-auto overflow-visible ${className ?? ''}`}
    >
      <defs>
        <mask
          id="hero-swoosh-trazo"
          maskUnits="userSpaceOnUse"
          x="-10"
          y="-10"
          width="500"
          height="52"
        >
          <path
            d="M2 29C150 26.5 320 18 474 7"
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
      <path
        d="M2 29C140 25 300 13 468 3C476 2.4 481 6.5 477 10.5C430 15.5 330 19 230 23C140 26.5 60 29.5 2 29Z"
        mask="url(#hero-swoosh-trazo)"
        className="fill-accent"
      />
    </svg>
  );
}

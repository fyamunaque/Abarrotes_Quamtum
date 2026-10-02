import Image from 'next/image';
import { Swoosh } from './Swoosh';

/**
 * Hero de la página principal. Su única animación al cargar es el swoosh bajo el titular
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
          <Swoosh draw className="mt-0.5" />
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

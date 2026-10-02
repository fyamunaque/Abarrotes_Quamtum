import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="rounded-2xl border-2 border-ink/10 bg-cream p-10 text-center">
      <h1 className="text-xl font-bold">No encontramos lo que buscabas</h1>
      <p className="mt-2 text-ink/70">
        Puede que el producto ya no esté disponible.
      </p>
      <Link
        href="/"
        className="mt-5 inline-block rounded-xl bg-primary px-5 py-2 font-semibold text-ink hover:bg-primary-dark hover:text-white"
      >
        Ver productos
      </Link>
    </div>
  );
}

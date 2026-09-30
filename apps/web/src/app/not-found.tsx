import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="rounded-2xl border border-stone-200 bg-white p-10 text-center">
      <h1 className="text-xl font-bold">No encontramos lo que buscabas</h1>
      <p className="mt-2 text-stone-600">
        Puede que el producto ya no esté disponible.
      </p>
      <Link
        href="/"
        className="mt-5 inline-block rounded-xl bg-brand-600 px-5 py-2 font-semibold text-white hover:bg-brand-700"
      >
        Ver productos
      </Link>
    </div>
  );
}

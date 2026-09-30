'use client'; // Los error boundaries deben ser Client Components.

import { useEffect } from 'react';

export default function ErrorPage({
  error,
  retry,
}: {
  error: Error & { digest?: string };
  retry: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="rounded-2xl border border-stone-200 bg-white p-10 text-center">
      <h1 className="text-xl font-bold">No pudimos cargar esta página</h1>
      <p className="mt-2 text-stone-600">
        Puede ser un problema momentáneo de conexión con la tienda.
      </p>
      <button
        type="button"
        onClick={() => retry()}
        className="mt-5 rounded-xl bg-brand-600 px-5 py-2 font-semibold text-white hover:bg-brand-700"
      >
        Intentar de nuevo
      </button>
    </div>
  );
}

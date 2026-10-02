export default function Loading() {
  return (
    <div role="status" className="flex flex-col gap-4">
      <span className="sr-only">Cargando…</span>
      <div className="h-8 w-64 animate-pulse rounded-lg bg-ink/10" />
      <ul className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        {Array.from({ length: 8 }, (_, i) => (
          <li key={i} className="aspect-[3/4] animate-pulse rounded-2xl bg-ink/10" />
        ))}
      </ul>
    </div>
  );
}

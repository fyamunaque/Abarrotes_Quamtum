const dateTimeFormat = new Intl.DateTimeFormat('es-PE', {
  dateStyle: 'medium',
  timeStyle: 'short',
  // Hora de la tienda, no la del servidor donde corre Next.js.
  timeZone: 'America/Lima',
});

export function formatDateTime(iso: string): string {
  return dateTimeFormat.format(new Date(iso));
}

/** `2026-12-31T00:00:00.000Z` → `2026-12-31` (valor de un <input type="date">). */
export function toDateInputValue(iso: string | null): string {
  return iso ? iso.slice(0, 10) : '';
}

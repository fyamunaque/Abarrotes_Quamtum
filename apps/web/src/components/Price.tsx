import { formatMoney } from '@/lib/money';
import { Swoosh } from './Swoosh';

const SIZES = {
  md: { text: 'text-xl', swoosh: 'h-2' },
  lg: { text: 'text-4xl', swoosh: 'h-3' },
} as const;

/** Precio de producto: Baloo 2 en negrita con el trazo del logo debajo, del ancho del número. */
export function Price({ amount, size = 'md' }: { amount: string; size?: keyof typeof SIZES }) {
  const { text, swoosh } = SIZES[size];
  return (
    <span className="inline-flex w-fit flex-col">
      <span className={`font-display leading-none font-bold ${text}`}>{formatMoney(amount)}</span>
      <Swoosh stretch className={`mt-1 ${swoosh}`} />
    </span>
  );
}

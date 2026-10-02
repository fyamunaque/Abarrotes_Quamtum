'use client';

interface QuantityStepperProps {
  quantity: number;
  max: number;
  onChange: (quantity: number) => void;
  label: string;
}

export function QuantityStepper({ quantity, max, onChange, label }: QuantityStepperProps) {
  const button =
    'flex h-9 w-9 items-center justify-center rounded-lg text-lg font-semibold text-primary-dark hover:bg-primary-tint disabled:text-ink/30 disabled:hover:bg-transparent';

  return (
    <div
      role="group"
      aria-label={`Cantidad de ${label}`}
      className="inline-flex items-center rounded-xl border-2 border-ink/10 bg-cream"
    >
      <button
        type="button"
        className={button}
        onClick={() => onChange(quantity - 1)}
        aria-label={`Quitar uno de ${label}`}
      >
        −
      </button>
      <span className="min-w-8 text-center font-medium tabular-nums" aria-live="polite">
        {quantity}
      </span>
      <button
        type="button"
        className={button}
        onClick={() => onChange(quantity + 1)}
        disabled={quantity >= max}
        aria-label={`Agregar uno de ${label}`}
      >
        +
      </button>
    </div>
  );
}

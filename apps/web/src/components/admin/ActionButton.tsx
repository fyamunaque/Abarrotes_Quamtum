'use client';

import { useState, useTransition } from 'react';
import type { ActionResult } from '@/lib/action-result';

const tones = {
  primary: 'bg-primary text-ink hover:bg-primary-dark hover:text-white',
  secondary: 'border border-ink/20 bg-cream hover:border-primary-dark hover:text-primary-dark',
  danger: 'border border-red-200 bg-cream text-red-700 hover:bg-red-50',
} as const;

interface ActionButtonProps {
  label: string;
  /** Server Action ya enlazada a sus argumentos (`action.bind(null, ...)`). */
  action: () => Promise<ActionResult>;
  confirmMessage?: string;
  tone?: keyof typeof tones;
}

export function ActionButton({ label, action, confirmMessage, tone = 'primary' }: ActionButtonProps) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function run() {
    if (confirmMessage && !window.confirm(confirmMessage)) return;
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (!result.ok) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col items-start gap-1">
      <button
        type="button"
        onClick={run}
        disabled={pending}
        className={`rounded-lg px-3 py-1.5 text-sm font-semibold disabled:cursor-wait disabled:opacity-60 ${tones[tone]}`}
      >
        {pending ? 'Guardando…' : label}
      </button>
      {error && (
        <p role="alert" className="max-w-xs text-xs text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}

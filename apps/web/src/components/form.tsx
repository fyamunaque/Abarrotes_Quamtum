import type { InputHTMLAttributes, ReactNode } from 'react';

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  name: string;
}

export function TextField({ label, name, ...inputProps }: TextFieldProps) {
  return (
    <label className="flex flex-col gap-1 text-sm font-medium">
      {label}
      <input
        name={name}
        {...inputProps}
        className="rounded-xl border border-stone-300 px-4 py-2 text-base font-normal outline-none focus:border-brand-600 focus:ring-2 focus:ring-brand-200"
      />
    </label>
  );
}

export function FormError({ message }: { message: string | null }) {
  // aria-live: los lectores de pantalla anuncian el error sin mover el foco.
  return (
    <p aria-live="polite" className="whitespace-pre-line text-sm text-red-700">
      {message}
    </p>
  );
}

export function SubmitButton({ pending, children }: { pending: boolean; children: ReactNode }) {
  return (
    <button
      type="submit"
      disabled={pending}
      className="rounded-xl bg-brand-600 px-5 py-3 font-semibold text-white hover:bg-brand-700 disabled:cursor-not-allowed disabled:bg-stone-300"
    >
      {pending ? 'Un momento…' : children}
    </button>
  );
}

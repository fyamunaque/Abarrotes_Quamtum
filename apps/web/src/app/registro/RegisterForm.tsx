'use client';

import { useActionState } from 'react';
import { type AuthFormState, register } from '@/app/actions/auth';
import { FormError, SubmitButton, TextField } from '@/components/form';

const initialState: AuthFormState = { error: null };

export function RegisterForm({ next }: { next: string }) {
  const [state, formAction, pending] = useActionState(register, initialState);
  const values = state.values ?? {};

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <input type="hidden" name="next" value={next} />
      <TextField label="Nombre" name="name" autoComplete="name" required defaultValue={values.name} />
      <TextField
        label="Email"
        name="email"
        type="email"
        autoComplete="email"
        required
        defaultValue={values.email}
      />
      <TextField
        label="Contraseña (mínimo 8 caracteres)"
        name="password"
        type="password"
        autoComplete="new-password"
        minLength={8}
        maxLength={72}
        required
      />
      <TextField
        label="Teléfono (opcional)"
        name="phone"
        type="tel"
        autoComplete="tel"
        maxLength={20}
        defaultValue={values.phone}
      />
      <TextField
        label="Dirección de entrega (opcional)"
        name="address"
        autoComplete="street-address"
        maxLength={255}
        defaultValue={values.address}
      />
      <FormError message={state.error} />
      <SubmitButton pending={pending}>Crear cuenta</SubmitButton>
    </form>
  );
}

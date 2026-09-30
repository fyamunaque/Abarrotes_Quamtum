'use client';

import { useActionState } from 'react';
import { type AuthFormState, login } from '@/app/actions/auth';
import { FormError, SubmitButton, TextField } from '@/components/form';

const initialState: AuthFormState = { error: null };

export function LoginForm({ next }: { next: string }) {
  const [state, formAction, pending] = useActionState(login, initialState);

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <input type="hidden" name="next" value={next} />
      <TextField
        label="Email"
        name="email"
        type="email"
        autoComplete="email"
        required
        defaultValue={state.values?.email}
      />
      <TextField
        label="Contraseña"
        name="password"
        type="password"
        autoComplete="current-password"
        required
      />
      <FormError message={state.error} />
      <SubmitButton pending={pending}>Ingresar</SubmitButton>
    </form>
  );
}

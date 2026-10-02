import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { firstParam, safeRedirectPath } from '@/lib/navigation';
import { getSessionUser } from '@/lib/session';
import { LoginForm } from './LoginForm';

export const metadata: Metadata = { title: 'Ingresar' };

export default async function LoginPage({ searchParams }: PageProps<'/ingresar'>) {
  const next = safeRedirectPath(firstParam((await searchParams).next));
  if (await getSessionUser()) redirect(next);

  return (
    <div className="mx-auto flex max-w-md flex-col gap-6 rounded-2xl border-2 border-ink/10 bg-cream p-8">
      <h1 className="text-2xl font-bold">Ingresar</h1>
      <LoginForm next={next} />
      <p className="text-center text-sm text-ink/70">
        ¿No tienes cuenta?{' '}
        <Link
          href={`/registro?next=${encodeURIComponent(next)}`}
          className="font-semibold text-primary-dark hover:underline"
        >
          Regístrate
        </Link>
      </p>
    </div>
  );
}

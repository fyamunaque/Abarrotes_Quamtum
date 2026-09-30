import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { getCurrentUser } from '@/lib/admin-api';
import { isStaffRole } from '@/lib/session-cookies';
import { AdminNav } from './AdminNav';

export const metadata: Metadata = {
  title: { default: 'Administración', template: '%s · Admin · Abarrotes' },
  robots: { index: false },
};

export default async function AdminLayout({ children }: LayoutProps<'/admin'>) {
  // El rol se consulta a la API (GET /auth/me), no a la cookie: es la fuente de verdad.
  // Este layout solo decide qué se ve: NO impide que las páginas se ejecuten (Next.js
  // las renderiza en paralelo). Por eso cada página llama a getStaffUser() antes de leer
  // datos, y la API vuelve a responder 403 a quien no sea staff.
  const user = await getCurrentUser();
  if (!user) redirect('/ingresar?next=/admin');

  if (!isStaffRole(user.role)) {
    return (
      <div className="rounded-2xl border border-stone-200 bg-white p-10 text-center">
        <h1 className="text-xl font-bold">No tienes acceso a la administración</h1>
        <p className="mt-2 text-stone-600">Esta sección es solo para el personal de la tienda.</p>
        <Link href="/" className="mt-5 inline-block font-semibold text-brand-700 hover:underline">
          Volver a la tienda
        </Link>
      </div>
    );
  }

  return (
    <div className="grid gap-6 md:grid-cols-[12rem_1fr]">
      <aside className="flex flex-col gap-3">
        <p className="text-sm text-stone-500">
          {user.name} · {user.role === 'ADMIN' ? 'Administrador' : 'Personal'}
        </p>
        <AdminNav />
      </aside>
      <section className="min-w-0">{children}</section>
    </div>
  );
}

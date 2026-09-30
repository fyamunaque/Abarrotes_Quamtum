import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { getSessionUser } from '@/lib/session';
import { CheckoutForm } from './CheckoutForm';

export const metadata: Metadata = { title: 'Confirmar pedido' };

export default async function CheckoutPage() {
  const user = await getSessionUser();
  if (!user) redirect('/ingresar?next=/checkout');

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-bold">Confirmar pedido</h1>
      <CheckoutForm userName={user.name} defaultAddress={user.address ?? ''} />
    </div>
  );
}

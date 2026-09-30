import type { Metadata } from 'next';
import { CartView } from './CartView';

export const metadata: Metadata = { title: 'Carrito' };

export default function CartPage() {
  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-bold">Tu carrito</h1>
      <CartView />
    </div>
  );
}

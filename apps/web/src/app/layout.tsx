import type { Metadata } from 'next';
import { CartHydrator } from '@/components/CartHydrator';
import { Header } from '@/components/Header';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'Abarrotes — Tienda online',
    template: '%s · Abarrotes',
  },
  description: 'Compra tus abarrotes en línea y recíbelos en casa.',
};

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="es">
      <body className="flex min-h-screen flex-col">
        <CartHydrator />
        <Header />
        <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6">{children}</main>
        <footer className="border-t border-stone-200 py-6 text-center text-sm text-stone-500">
          Abarrotes · Pedidos en línea
        </footer>
      </body>
    </html>
  );
}

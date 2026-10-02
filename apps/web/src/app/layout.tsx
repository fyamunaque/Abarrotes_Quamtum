import type { Metadata } from 'next';
import { Baloo_2, Inter } from 'next/font/google';
import { CartHydrator } from '@/components/CartHydrator';
import { Header } from '@/components/Header';
import './globals.css';

// Tipografía de marca de Neil's. next/font las descarga al compilar y las sirve desde el
// propio sitio; globals.css las expone a Tailwind como font-display y font-sans.
const baloo = Baloo_2({
  subsets: ['latin'],
  weight: ['600', '700', '800'],
  display: 'swap',
  variable: '--font-baloo',
});

const inter = Inter({
  subsets: ['latin'],
  weight: ['400', '500', '600'],
  display: 'swap',
  variable: '--font-inter',
});

export const metadata: Metadata = {
  title: {
    default: 'Abarrotes — Tienda online',
    template: '%s · Abarrotes',
  },
  description: 'Compra tus abarrotes en línea y recíbelos en casa.',
};

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="es" className={`${baloo.variable} ${inter.variable}`}>
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

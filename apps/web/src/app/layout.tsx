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
    default: "Neil's Food Services — Tienda online",
    template: "%s · Neil's Food Services",
  },
  description: "Compra tus abarrotes en línea en Neil's Food Services y recíbelos en casa.",
};

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="es" className={`${baloo.variable} ${inter.variable}`}>
      <body className="flex min-h-screen flex-col">
        <CartHydrator />
        <Header />
        <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6">{children}</main>
        <footer className="border-t border-ink/10 py-6 text-center text-sm text-ink/60">
          Neil&apos;s Food Services. Abarrotes con entrega a domicilio.
        </footer>
      </body>
    </html>
  );
}

'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const links = [
  { href: '/admin/pedidos', label: 'Pedidos' },
  { href: '/admin/productos', label: 'Productos' },
] as const;

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav aria-label="Administración" className="flex gap-2 md:flex-col">
      {links.map(({ href, label }) => {
        const active = pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? 'page' : undefined}
            className={`rounded-xl px-4 py-2 font-medium ${
              active ? 'bg-ink text-cream' : 'bg-cream hover:bg-primary-tint/50'
            }`}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}

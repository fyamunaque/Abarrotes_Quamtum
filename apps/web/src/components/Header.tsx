import Link from 'next/link';
import { logout } from '@/app/actions/auth';
import { getSessionUser } from '@/lib/session';
import { isStaffRole } from '@/lib/session-cookies';
import { CartLink } from './CartLink';

export async function Header() {
  const user = await getSessionUser();

  return (
    <header className="border-b border-stone-200 bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3">
        <Link href="/" className="text-xl font-bold text-brand-700">
          Abarrotes
        </Link>
        <nav className="flex items-center gap-1 text-sm">
          {/* Solo decide si mostrar el enlace; /admin vuelve a verificar el rol con la API. */}
          {user && isStaffRole(user.role) && (
            <Link href="/admin" className="rounded-xl px-3 py-2 font-medium hover:bg-stone-100">
              Admin
            </Link>
          )}
          <CartLink />
          {user ? (
            <form action={logout} className="flex items-center gap-2">
              <span className="hidden text-stone-600 sm:inline">Hola, {user.name}</span>
              <button type="submit" className="rounded-xl px-3 py-2 font-medium hover:bg-stone-100">
                Salir
              </button>
            </form>
          ) : (
            <Link href="/ingresar" className="rounded-xl px-3 py-2 font-medium hover:bg-stone-100">
              Ingresar
            </Link>
          )}
        </nav>
      </div>
    </header>
  );
}

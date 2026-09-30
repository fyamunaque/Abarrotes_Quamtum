import { compare, hash } from 'bcryptjs';

// bcryptjs implementa el mismo algoritmo bcrypt (hashes $2a$/$2b$ compatibles con el
// paquete nativo `bcrypt`) sin compilar código nativo, así que instala igual en Windows,
// Linux y en el CI.

/** Costo de bcrypt: ~70 ms por hash. Lento para fuerza bruta, rápido para un login. */
export const BCRYPT_ROUNDS = 10;

export function hashPassword(password: string): Promise<string> {
  return hash(password, BCRYPT_ROUNDS);
}

export function verifyPassword(
  password: string,
  passwordHash: string,
): Promise<boolean> {
  return compare(password, passwordHash);
}

/**
 * Datos mínimos para poder usar la API: categorías base y el primer ADMIN
 * (el registro público solo crea CUSTOMER). Idempotente: se puede correr varias veces.
 *
 *   npm run prisma:seed
 */
import { PrismaClient, UserRole } from '@prisma/client';
import { hash } from 'bcryptjs';
import { BCRYPT_ROUNDS } from '../src/auth/auth.constants';

const CATEGORIES = [
  'Abarrotes',
  'Bebidas',
  'Lácteos y huevos',
  'Carnes y embutidos',
  'Frutas y verduras',
  'Panadería',
  'Snacks y dulces',
  'Limpieza',
  'Cuidado personal',
];

const prisma = new PrismaClient();

async function seedCategories(): Promise<void> {
  for (const name of CATEGORIES) {
    await prisma.category.upsert({
      where: { name },
      update: {},
      create: { name },
    });
  }
  console.log(`Categorías: ${CATEGORIES.length} verificadas.`);
}

async function seedAdmin(): Promise<void> {
  const email = process.env.SEED_ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.SEED_ADMIN_PASSWORD;
  if (!email || !password) {
    console.warn(
      'SEED_ADMIN_EMAIL o SEED_ADMIN_PASSWORD vacíos: no se creó el admin inicial.',
    );
    return;
  }
  if (password.length < 8) {
    throw new Error('SEED_ADMIN_PASSWORD debe tener al menos 8 caracteres.');
  }

  // Si el usuario ya existe no se toca (ni su contraseña ni su rol).
  await prisma.user.upsert({
    where: { email },
    update: {},
    create: {
      email,
      name: process.env.SEED_ADMIN_NAME?.trim() || 'Administrador',
      role: UserRole.ADMIN,
      passwordHash: await hash(password, BCRYPT_ROUNDS),
    },
  });
  console.log(`Admin inicial: ${email}`);
}

async function main(): Promise<void> {
  await seedCategories();
  await seedAdmin();
}

void main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());

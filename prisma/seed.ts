/**
 * Datos de desarrollo: categorías, productos de ejemplo para el catálogo y un ADMIN de
 * prueba cuyas credenciales se imprimen al terminar. Se puede correr varias veces.
 *
 *   cd apps/api && npx prisma db seed
 *
 * La configuración está en apps/api/package.json ("prisma.seed").
 */
import { PrismaClient, UserRole } from "@prisma/client";
import { hash } from "bcryptjs";
import { randomBytes } from "node:crypto";

// Mismo costo que apps/api/src/common/password.ts.
const BCRYPT_ROUNDS = 10;

// Dominio reservado (RFC 2606): nunca es la cuenta de alguien real.
const DEFAULT_ADMIN_EMAIL = "admin@abarrotes.test";

const CATEGORIES = [
  "Abarrotes",
  "Bebidas",
  "Lácteos y huevos",
  "Carnes y embutidos",
  "Frutas y verduras",
  "Panadería",
  "Snacks y dulces",
  "Limpieza",
  "Cuidado personal",
];

const PRODUCTS = [
  {
    sku: "DEMO-ARROZ-1KG",
    name: "Arroz extra 1 kg",
    description: "Arroz blanco de grano largo.",
    category: "Abarrotes",
    price: "4.50",
    currentStock: 50,
    minStock: 10,
  },
  {
    sku: "DEMO-ACEITE-1L",
    name: "Aceite vegetal 1 L",
    description: "Aceite vegetal para cocinar.",
    category: "Abarrotes",
    price: "9.90",
    currentStock: 30,
    minStock: 8,
  },
  {
    sku: "DEMO-LECHE-400G",
    name: "Leche evaporada 400 g",
    description: "Leche evaporada entera en lata.",
    category: "Lácteos y huevos",
    price: "4.20",
    currentStock: 48,
    minStock: 12,
    expirationDate: new Date("2027-06-30"),
  },
  {
    sku: "DEMO-DETERGENTE-800G",
    name: "Detergente en polvo 800 g",
    description: "Detergente para ropa blanca y de color.",
    category: "Limpieza",
    price: "11.50",
    // Por debajo del mínimo a propósito: muestra el aviso de stock bajo en el admin.
    currentStock: 4,
    minStock: 5,
  },
];

const prisma = new PrismaClient();

async function seedCategories(): Promise<Map<string, string>> {
  const idsByName = new Map<string, string>();
  for (const name of CATEGORIES) {
    const category = await prisma.category.upsert({
      where: { name },
      update: {},
      create: { name },
    });
    idsByName.set(name, category.id);
  }
  return idsByName;
}

/** Crea los que falten. Los que ya existen no se tocan (pueden haberse editado en el admin). */
async function seedProducts(categoryIds: Map<string, string>): Promise<number> {
  let created = 0;
  for (const { category, ...product } of PRODUCTS) {
    const exists = await prisma.product.findUnique({
      where: { sku: product.sku },
    });
    if (exists) continue;

    const categoryId = categoryIds.get(category);
    if (!categoryId)
      throw new Error(`Categoría inexistente en el seed: ${category}`);
    await prisma.product.create({ data: { ...product, categoryId } });
    created++;
  }
  return created;
}

/**
 * Si el usuario ya existe se le fija esta contraseña y el rol ADMIN, para que las
 * credenciales que se imprimen siempre sirvan para entrar.
 */
async function seedAdmin(): Promise<{
  email: string;
  password: string;
  generated: boolean;
}> {
  const email = (
    process.env.SEED_ADMIN_EMAIL?.trim() || DEFAULT_ADMIN_EMAIL
  ).toLowerCase();
  const fromEnv = process.env.SEED_ADMIN_PASSWORD;
  const password = fromEnv || randomBytes(12).toString("base64url");
  if (password.length < 8) {
    throw new Error("SEED_ADMIN_PASSWORD debe tener al menos 8 caracteres.");
  }

  const passwordHash = await hash(password, BCRYPT_ROUNDS);
  await prisma.user.upsert({
    where: { email },
    update: { passwordHash, role: UserRole.ADMIN },
    create: {
      email,
      name: process.env.SEED_ADMIN_NAME?.trim() || "Administrador de prueba",
      role: UserRole.ADMIN,
      passwordHash,
    },
  });
  return { email, password, generated: !fromEnv };
}

async function main(): Promise<void> {
  // Un admin con la contraseña impresa en la consola no puede existir en producción.
  if (process.env.NODE_ENV === "production") {
    throw new Error(
      "El seed es solo para desarrollo (crea un admin de prueba y productos de ejemplo). " +
        "No se ejecuta con NODE_ENV=production.",
    );
  }

  const categoryIds = await seedCategories();
  const createdProducts = await seedProducts(categoryIds);
  const admin = await seedAdmin();

  console.log("\nSeed completado.");
  console.log(`  Categorías:  ${categoryIds.size}`);
  console.log(
    `  Productos:   ${PRODUCTS.length} de ejemplo (${createdProducts} nuevos)`,
  );
  console.log("\n  Admin de prueba (solo desarrollo):");
  console.log(`    Email:       ${admin.email}`);
  console.log(`    Contraseña:  ${admin.password}`);
  if (admin.generated) {
    console.log(
      "    (generada al azar; define SEED_ADMIN_PASSWORD en .env para fijarla)",
    );
  }
}

main()
  .catch((error: unknown) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());

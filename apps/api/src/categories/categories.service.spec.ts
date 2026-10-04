import { ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CategoriesService } from './categories.service';

const ID = 'aaaaaaaa-0000-4000-8000-000000000001';

describe('CategoriesService', () => {
  let prisma: {
    category: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
    product: { count: jest.Mock };
  };
  let service: CategoriesService;

  beforeEach(() => {
    prisma = {
      category: {
        findMany: jest.fn(),
        findUnique: jest.fn().mockResolvedValue({ id: ID, name: 'Bebidas' }),
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest
          .fn()
          .mockImplementation(({ data }) =>
            Promise.resolve({ id: ID, ...data }),
          ),
        update: jest.fn(),
        delete: jest.fn(),
      },
      product: { count: jest.fn().mockResolvedValue(0) },
    };
    service = new CategoriesService(prisma as unknown as PrismaService);
  });

  it('crea la categoría si el nombre está libre', async () => {
    await expect(service.create({ name: 'Snacks' })).resolves.toEqual({
      id: ID,
      name: 'Snacks',
    });
  });

  it('rechaza un nombre repetido sin distinguir mayúsculas', async () => {
    prisma.category.findFirst.mockResolvedValue({ name: 'Bebidas' });

    await expect(service.create({ name: 'bebidas' })).rejects.toThrow(
      new ConflictException('Ya existe la categoría "Bebidas"'),
    );
    expect(prisma.category.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { name: { equals: 'bebidas', mode: 'insensitive' } },
      }),
    );
    expect(prisma.category.create).not.toHaveBeenCalled();
  });

  it('al renombrar no choca consigo misma', async () => {
    await service.update(ID, { name: 'BEBIDAS' });

    expect(prisma.category.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          name: { equals: 'BEBIDAS', mode: 'insensitive' },
          id: { not: ID },
        },
      }),
    );
  });

  it('no deja borrar una categoría con productos', async () => {
    prisma.product.count.mockResolvedValue(3);

    await expect(service.remove(ID)).rejects.toThrow(
      new ConflictException(
        'La categoría tiene 3 productos: muévelos a otra antes de eliminarla',
      ),
    );
    expect(prisma.category.delete).not.toHaveBeenCalled();
  });

  it('borra una categoría sin productos', async () => {
    await service.remove(ID);

    expect(prisma.category.delete).toHaveBeenCalledWith({ where: { id: ID } });
  });

  it('responde 404 si la categoría no existe', async () => {
    prisma.category.findUnique.mockResolvedValue(null);

    await expect(service.findOne(ID)).rejects.toBeInstanceOf(NotFoundException);
    await expect(service.remove(ID)).rejects.toBeInstanceOf(NotFoundException);
  });
});

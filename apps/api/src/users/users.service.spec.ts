import { ConflictException } from '@nestjs/common';
import { Prisma, User, UserRole } from '@prisma/client';
import { compare } from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from './users.service';

describe('UsersService.createStaff', () => {
  let service: UsersService;
  let create: jest.Mock;

  const dto = {
    email: 'cajera@example.com',
    password: 'clave-segura-123',
    name: 'Cajera',
    role: UserRole.STAFF,
  };

  beforeEach(() => {
    create = jest.fn(({ data }: { data: Prisma.UserCreateInput }) =>
      Promise.resolve({
        id: 'u1',
        phone: null,
        address: null,
        createdAt: new Date(),
        ...data,
      } as User),
    );
    service = new UsersService({
      user: { create },
    } as unknown as PrismaService);
  });

  it('crea el usuario con el rol pedido y la contraseña hasheada', async () => {
    const user = await service.createStaff(dto);

    const { data } = create.mock.calls[0][0] as {
      data: Prisma.UserCreateInput;
    };
    expect(data.role).toBe(UserRole.STAFF);
    expect(data.passwordHash).not.toBe(dto.password);
    expect(await compare(dto.password, data.passwordHash)).toBe(true);

    expect(user.role).toBe(UserRole.STAFF);
    expect(user).not.toHaveProperty('passwordHash');
  });

  it('responde 409 si el email ya existe', async () => {
    create.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
        code: 'P2002',
        clientVersion: 'test',
      }),
    );

    await expect(service.createStaff(dto)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });
});

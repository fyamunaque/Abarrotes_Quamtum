import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Prisma, User, UserRole } from '@prisma/client';
import { compare, hash } from 'bcryptjs';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { JwtPayload } from './auth.types';

const env: Record<string, string> = {
  JWT_ACCESS_SECRET: 'test-access-secret',
  JWT_REFRESH_SECRET: 'test-refresh-secret',
};

const config = {
  getOrThrow: (key: string) => env[key],
  get: (key: string, defaultValue?: string) => env[key] ?? defaultValue,
} as unknown as ConfigService;

function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: 'user-1',
    email: 'cliente@example.com',
    passwordHash: 'hash',
    name: 'Cliente',
    phone: null,
    role: UserRole.CUSTOMER,
    address: null,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    ...overrides,
  };
}

describe('AuthService', () => {
  let service: AuthService;
  let jwtService: JwtService;
  let usersService: jest.Mocked<
    Pick<UsersService, 'findByEmail' | 'findById' | 'create'>
  >;

  beforeEach(() => {
    usersService = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
    };
    jwtService = new JwtService({});
    service = new AuthService(
      usersService as unknown as UsersService,
      jwtService,
      config,
    );
  });

  describe('register', () => {
    const dto = {
      email: 'nuevo@example.com',
      password: 'contrasena-segura',
      name: 'Nuevo',
    };

    it('crea un CUSTOMER con la contraseña hasheada y no expone el hash', async () => {
      usersService.create.mockImplementation((data) =>
        Promise.resolve(
          buildUser({
            email: data.email,
            name: data.name,
            passwordHash: data.passwordHash,
          }),
        ),
      );

      const result = await service.register(dto);

      const data = usersService.create.mock.calls[0][0];
      expect(data.role).toBe(UserRole.CUSTOMER);
      expect(data.passwordHash).not.toBe(dto.password);
      expect(await compare(dto.password, data.passwordHash)).toBe(true);

      expect(result.user).not.toHaveProperty('passwordHash');
      expect(result.user.role).toBe(UserRole.CUSTOMER);
      expect(result.accessToken).toEqual(expect.any(String));
      expect(result.refreshToken).toEqual(expect.any(String));
    });

    it('fuerza CUSTOMER aunque el objeto traiga otro rol', async () => {
      usersService.create.mockResolvedValue(buildUser());

      // Simula un DTO manipulado: el tipo no lo permite, pero el servicio no debe
      // depender de eso.
      await service.register({ ...dto, role: UserRole.ADMIN } as never);

      expect(usersService.create.mock.calls[0][0].role).toBe(UserRole.CUSTOMER);
    });

    it('responde 409 si el email ya existe', async () => {
      usersService.create.mockRejectedValue(
        new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
          code: 'P2002',
          clientVersion: 'test',
        }),
      );

      await expect(service.register(dto)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('login', () => {
    it('devuelve tokens con el rol del usuario si la contraseña es correcta', async () => {
      usersService.findByEmail.mockResolvedValue(
        buildUser({
          role: UserRole.ADMIN,
          passwordHash: await hash('contrasena-segura', 4),
        }),
      );

      const result = await service.login({
        email: 'cliente@example.com',
        password: 'contrasena-segura',
      });

      const payload = await jwtService.verifyAsync<JwtPayload>(
        result.accessToken,
        { secret: env.JWT_ACCESS_SECRET },
      );
      expect(payload).toMatchObject({ sub: 'user-1', role: UserRole.ADMIN });
    });

    it('rechaza una contraseña incorrecta', async () => {
      usersService.findByEmail.mockResolvedValue(
        buildUser({ passwordHash: await hash('contrasena-segura', 4) }),
      );

      await expect(
        service.login({ email: 'cliente@example.com', password: 'otra-cosa' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rechaza un email inexistente', async () => {
      usersService.findByEmail.mockResolvedValue(null);

      await expect(
        service.login({ email: 'nadie@example.com', password: 'lo-que-sea' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    it('emite un par nuevo con el rol actual del usuario', async () => {
      const refreshToken = await jwtService.signAsync(
        {
          sub: 'user-1',
          email: 'cliente@example.com',
          role: UserRole.CUSTOMER,
        },
        { secret: env.JWT_REFRESH_SECRET },
      );
      // Después de emitido el token, el usuario fue promovido a STAFF.
      usersService.findById.mockResolvedValue(
        buildUser({ role: UserRole.STAFF }),
      );

      const result = await service.refresh(refreshToken);

      const payload = await jwtService.verifyAsync<JwtPayload>(
        result.accessToken,
        { secret: env.JWT_ACCESS_SECRET },
      );
      expect(payload.role).toBe(UserRole.STAFF);
    });

    it('rechaza un access token usado como refresh token', async () => {
      const accessToken = await jwtService.signAsync(
        {
          sub: 'user-1',
          email: 'cliente@example.com',
          role: UserRole.CUSTOMER,
        },
        { secret: env.JWT_ACCESS_SECRET },
      );

      await expect(service.refresh(accessToken)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('rechaza el refresh si el usuario ya no existe', async () => {
      const refreshToken = await jwtService.signAsync(
        { sub: 'borrado', email: 'x@example.com', role: UserRole.CUSTOMER },
        { secret: env.JWT_REFRESH_SECRET },
      );
      usersService.findById.mockResolvedValue(null);

      await expect(service.refresh(refreshToken)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });
});

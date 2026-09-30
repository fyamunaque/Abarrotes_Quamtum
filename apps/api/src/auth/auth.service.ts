import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { User, UserRole } from '@prisma/client';
import { hashPassword, verifyPassword } from '../common/password';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PublicUser, toPublicUser, UsersService } from '../users/users.service';
import {
  DEFAULT_ACCESS_EXPIRES_IN,
  DEFAULT_REFRESH_EXPIRES_IN,
} from './auth.constants';
import { AuthResponse, AuthTokens, JwtPayload } from './auth.types';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

type ExpiresIn = JwtSignOptions['expiresIn'];

@Injectable()
export class AuthService {
  private readonly accessSecret: string;
  private readonly refreshSecret: string;
  private readonly accessExpiresIn: ExpiresIn;
  private readonly refreshExpiresIn: ExpiresIn;

  // Si el email no existe igual se compara contra un hash, para que el tiempo de
  // respuesta no revele qué emails están registrados.
  private readonly dummyHash = hashPassword('dummy-password');

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    config: ConfigService,
  ) {
    this.accessSecret = config.getOrThrow<string>('JWT_ACCESS_SECRET');
    this.refreshSecret = config.getOrThrow<string>('JWT_REFRESH_SECRET');
    this.accessExpiresIn = config.get<string>(
      'JWT_ACCESS_EXPIRES_IN',
      DEFAULT_ACCESS_EXPIRES_IN,
    ) as ExpiresIn;
    this.refreshExpiresIn = config.get<string>(
      'JWT_REFRESH_EXPIRES_IN',
      DEFAULT_REFRESH_EXPIRES_IN,
    ) as ExpiresIn;
  }

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const passwordHash = await hashPassword(dto.password);
    try {
      // Rol forzado: nunca se toma del body. ADMIN/STAFF solo se crean con el seed
      // o con POST /users (solo ADMIN).
      const user = await this.usersService.create({
        role: UserRole.CUSTOMER,
        email: dto.email,
        passwordHash,
        name: dto.name,
        phone: dto.phone,
        address: dto.address,
      });
      return this.buildAuthResponse(user);
    } catch (error) {
      if (isPrismaError(error, PrismaErrorCode.UniqueConstraint)) {
        throw new ConflictException('El email ya está registrado');
      }
      throw error;
    }
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    const user = await this.usersService.findByEmail(dto.email);
    const passwordMatches = await verifyPassword(
      dto.password,
      user?.passwordHash ?? (await this.dummyHash),
    );
    if (!user || !passwordMatches) {
      throw new UnauthorizedException('Email o contraseña incorrectos');
    }
    return this.buildAuthResponse(user);
  }

  /**
   * Emite un par nuevo a partir de un refresh token válido. Relee el usuario para
   * que un cambio de rol o una baja se reflejen en el siguiente refresh.
   */
  async refresh(refreshToken: string): Promise<AuthResponse> {
    let payload: JwtPayload;
    try {
      payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken, {
        secret: this.refreshSecret,
      });
    } catch {
      throw new UnauthorizedException('Refresh token inválido o expirado');
    }

    const user = await this.usersService.findById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('Refresh token inválido o expirado');
    }
    return this.buildAuthResponse(user);
  }

  async me(userId: string): Promise<PublicUser> {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }
    return toPublicUser(user);
  }

  private async buildAuthResponse(user: User): Promise<AuthResponse> {
    const tokens = await this.issueTokens(user);
    return { ...tokens, user: toPublicUser(user) };
  }

  private async issueTokens(user: User): Promise<AuthTokens> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.accessSecret,
        expiresIn: this.accessExpiresIn,
      }),
      this.jwtService.signAsync(payload, {
        secret: this.refreshSecret,
        expiresIn: this.refreshExpiresIn,
      }),
    ]);
    return { accessToken, refreshToken };
  }
}

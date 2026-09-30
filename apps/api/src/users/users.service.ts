import { ConflictException, Injectable } from '@nestjs/common';
import { Prisma, User } from '@prisma/client';
import { hashPassword } from '../common/password';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';

/** Usuario tal como se expone en la API: nunca incluye el hash de la contraseña. */
export type PublicUser = Omit<User, 'passwordHash'>;

export function toPublicUser(user: User): PublicUser {
  const { passwordHash, ...publicUser } = user;
  return publicUser;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  /** Alta de ADMIN o STAFF (POST /users, solo ADMIN). */
  async createStaff(dto: CreateStaffUserDto): Promise<PublicUser> {
    try {
      const user = await this.create({
        email: dto.email,
        name: dto.name,
        phone: dto.phone,
        role: dto.role,
        passwordHash: await hashPassword(dto.password),
      });
      return toPublicUser(user);
    } catch (error) {
      if (isPrismaError(error, PrismaErrorCode.UniqueConstraint)) {
        throw new ConflictException('El email ya está registrado');
      }
      throw error;
    }
  }
}

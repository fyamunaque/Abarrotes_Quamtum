import { Body, Controller, Post } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Única forma de crear cuentas ADMIN o STAFF (además del seed del primer ADMIN).
   * Los clientes se registran solos con POST /auth/register.
   */
  @Roles(UserRole.ADMIN)
  @Post()
  create(@Body() dto: CreateStaffUserDto) {
    return this.usersService.createStaff(dto);
  }
}

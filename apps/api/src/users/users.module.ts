import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  // `auth` lo usa para registrar, buscar y leer usuarios.
  exports: [UsersService],
})
export class UsersModule {}

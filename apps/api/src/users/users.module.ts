import { Module } from '@nestjs/common';
import { UsersService } from './users.service';

// Por ahora solo expone el servicio que usa `auth`. El controller (gestión de
// clientes y subusuarios) llega con el dashboard admin, en la Fase 3.
@Module({
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

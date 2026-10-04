import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AuthModule } from './auth/auth.module';
import { CategoriesModule } from './categories/categories.module';
import { ClockModule } from './common/clock';
import { validateEnv } from './config/env.validation';
import { InventoryModule } from './inventory/inventory.module';
import { OrdersModule } from './orders/orders.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProductsModule } from './products/products.module';
import { PromotionsModule } from './promotions/promotions.module';
import { StatsModule } from './stats/stats.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    PrismaModule,
    ClockModule,
    UsersModule,
    AuthModule,
    CategoriesModule,
    ProductsModule,
    PromotionsModule,
    OrdersModule,
    InventoryModule,
    StatsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}

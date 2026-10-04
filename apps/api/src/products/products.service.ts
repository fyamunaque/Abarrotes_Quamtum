import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthUser, isStaff } from '../auth/auth.types';
import { Clock, CLOCK } from '../common/clock';
import { paginate, toSkipTake } from '../common/pagination';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import {
  activePromotionWhere,
  toDayPeriod,
} from '../promotions/promotion-rules';
import { CreateProductDto } from './dto/create-product.dto';
import { ListProductsQueryDto } from './dto/list-products-query.dto';
import { UpdateProductDto } from './dto/update-product.dto';

/**
 * El producto con su categoría y su promoción vigente. Como las promociones encendidas de
 * un producto no se cruzan en el tiempo, hay a lo sumo una.
 */
function productInclude(now: Date) {
  return {
    category: { select: { id: true, name: true } },
    promotions: {
      where: activePromotionWhere(now),
      select: { id: true, promoPrice: true, startDate: true, endDate: true },
      take: 1,
    },
  } satisfies Prisma.ProductInclude;
}

type ProductWithPromotions = Prisma.ProductGetPayload<{
  include: ReturnType<typeof productInclude>;
}>;

/** Cambia la lista `promotions` por `promotion`: la vigente, con días de la tienda, o null. */
function withPromotion({ promotions, ...product }: ProductWithPromotions) {
  const [current] = promotions;
  return {
    ...product,
    promotion: current
      ? {
          id: current.id,
          promoPrice: current.promoPrice,
          ...toDayPeriod(current),
        }
      : null,
  };
}

@Injectable()
export class ProductsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Clientes y anónimos solo ven productos activos. */
  async findAll(query: ListProductsQueryDto, user?: AuthUser) {
    const { categoryId, search } = query;
    const showInactive = query.includeInactive === true && isStaff(user);
    const now = this.clock.now();

    const where: Prisma.ProductWhereInput = { categoryId };
    if (!showInactive) {
      where.active = true;
    }
    if (query.onSale === true) {
      where.promotions = { some: activePromotionWhere(now) };
    }
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { sku: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        include: productInclude(now),
        orderBy: { name: 'asc' },
        ...toSkipTake(query),
      }),
      this.prisma.product.count({ where }),
    ]);

    return paginate(data.map(withPromotion), total, query);
  }

  async findOne(id: string, user?: AuthUser) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: productInclude(this.clock.now()),
    });
    if (!product || (!product.active && !isStaff(user))) {
      throw new NotFoundException('Producto no encontrado');
    }
    return withPromotion(product);
  }

  async create(dto: CreateProductDto) {
    try {
      return withPromotion(
        await this.prisma.product.create({
          data: { ...dto },
          include: productInclude(this.clock.now()),
        }),
      );
    } catch (error) {
      throw this.toHttpError(error, dto.sku);
    }
  }

  async update(id: string, dto: UpdateProductDto) {
    try {
      return withPromotion(
        await this.prisma.product.update({
          where: { id },
          data: { ...dto },
          include: productInclude(this.clock.now()),
        }),
      );
    } catch (error) {
      throw this.toHttpError(error, dto.sku);
    }
  }

  /**
   * Baja lógica (active = false). No se borra físicamente porque los pedidos,
   * movimientos de inventario y promociones lo referencian.
   */
  async deactivate(id: string) {
    try {
      return withPromotion(
        await this.prisma.product.update({
          where: { id },
          data: { active: false },
          include: productInclude(this.clock.now()),
        }),
      );
    } catch (error) {
      throw this.toHttpError(error);
    }
  }

  /** Traduce errores conocidos de Prisma a excepciones HTTP; el resto pasa tal cual. */
  private toHttpError(error: unknown, sku?: string): unknown {
    if (isPrismaError(error, PrismaErrorCode.UniqueConstraint)) {
      return new ConflictException(`Ya existe un producto con el SKU ${sku}`);
    }
    if (isPrismaError(error, PrismaErrorCode.ForeignKeyConstraint)) {
      return new BadRequestException('La categoría indicada no existe');
    }
    if (isPrismaError(error, PrismaErrorCode.RecordNotFound)) {
      return new NotFoundException('Producto no encontrado');
    }
    return error;
  }
}

import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthUser, isStaff } from '../auth/auth.types';
import { paginate, toSkipTake } from '../common/pagination';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { ListProductsQueryDto } from './dto/list-products-query.dto';
import { UpdateProductDto } from './dto/update-product.dto';

const productInclude = {
  category: { select: { id: true, name: true } },
} satisfies Prisma.ProductInclude;

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Clientes y anónimos solo ven productos activos. */
  async findAll(query: ListProductsQueryDto, user?: AuthUser) {
    const { categoryId, search } = query;
    const showInactive = query.includeInactive === true && isStaff(user);

    const where: Prisma.ProductWhereInput = { categoryId };
    if (!showInactive) {
      where.active = true;
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
        include: productInclude,
        orderBy: { name: 'asc' },
        ...toSkipTake(query),
      }),
      this.prisma.product.count({ where }),
    ]);

    return paginate(data, total, query);
  }

  async findOne(id: string, user?: AuthUser) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: productInclude,
    });
    if (!product || (!product.active && !isStaff(user))) {
      throw new NotFoundException('Producto no encontrado');
    }
    return product;
  }

  async create(dto: CreateProductDto) {
    try {
      return await this.prisma.product.create({
        data: { ...dto },
        include: productInclude,
      });
    } catch (error) {
      throw this.toHttpError(error, dto.sku);
    }
  }

  async update(id: string, dto: UpdateProductDto) {
    try {
      return await this.prisma.product.update({
        where: { id },
        data: { ...dto },
        include: productInclude,
      });
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
      return await this.prisma.product.update({
        where: { id },
        data: { active: false },
        include: productInclude,
      });
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

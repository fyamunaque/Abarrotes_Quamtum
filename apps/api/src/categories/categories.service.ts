import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

const categorySelect = { id: true, name: true } satisfies Prisma.CategorySelect;

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.category.findMany({
      select: categorySelect,
      orderBy: { name: 'asc' },
    });
  }

  async findOne(id: string) {
    const category = await this.prisma.category.findUnique({
      where: { id },
      select: categorySelect,
    });
    if (!category) {
      throw new NotFoundException('Categoría no encontrada');
    }
    return category;
  }

  async create(dto: CreateCategoryDto) {
    await this.assertNameIsFree(dto.name);
    try {
      return await this.prisma.category.create({
        data: { name: dto.name },
        select: categorySelect,
      });
    } catch (error) {
      throw this.toHttpError(error, dto.name);
    }
  }

  async update(id: string, dto: UpdateCategoryDto) {
    if (dto.name !== undefined) {
      await this.assertNameIsFree(dto.name, id);
    }
    try {
      return await this.prisma.category.update({
        where: { id },
        data: { name: dto.name },
        select: categorySelect,
      });
    } catch (error) {
      throw this.toHttpError(error, dto.name);
    }
  }

  /**
   * Borra la categoría solo si no tiene productos, ni siquiera inactivos: cada producto
   * necesita una categoría. Para eliminarla, primero hay que mover sus productos.
   */
  async remove(id: string) {
    await this.findOne(id);
    const products = await this.prisma.product.count({
      where: { categoryId: id },
    });
    if (products > 0) {
      throw new ConflictException(
        `La categoría tiene ${products} producto${products === 1 ? '' : 's'}: muévelos a otra antes de eliminarla`,
      );
    }
    try {
      await this.prisma.category.delete({ where: { id } });
    } catch (error) {
      throw this.toHttpError(error);
    }
  }

  /**
   * El índice único de la base distingue mayúsculas: "Bebidas" y "bebidas" pasarían.
   * Para la tienda son la misma categoría, así que se compara sin distinguirlas.
   */
  private async assertNameIsFree(name: string, exceptId?: string) {
    const existing = await this.prisma.category.findFirst({
      where: {
        name: { equals: name, mode: 'insensitive' },
        ...(exceptId && { id: { not: exceptId } }),
      },
      select: { name: true },
    });
    if (existing) {
      throw new ConflictException(`Ya existe la categoría "${existing.name}"`);
    }
  }

  /** Traduce errores conocidos de Prisma a excepciones HTTP; el resto pasa tal cual. */
  private toHttpError(error: unknown, name?: string): unknown {
    if (isPrismaError(error, PrismaErrorCode.UniqueConstraint)) {
      return new ConflictException(`Ya existe la categoría "${name}"`);
    }
    if (isPrismaError(error, PrismaErrorCode.RecordNotFound)) {
      return new NotFoundException('Categoría no encontrada');
    }
    // Un producto se asignó a la categoría justo mientras se borraba.
    if (isPrismaError(error, PrismaErrorCode.ForeignKeyConstraint)) {
      return new ConflictException(
        'La categoría tiene productos: muévelos a otra antes de eliminarla',
      );
    }
    return error;
  }
}

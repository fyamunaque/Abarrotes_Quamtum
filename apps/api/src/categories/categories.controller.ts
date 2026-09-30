import { Controller, Get } from '@nestjs/common';
import { Public } from '../auth/decorators/public.decorator';
import { CategoriesService } from './categories.service';

// Solo lectura por ahora; el alta/edición de categorías llega con el dashboard (Fase 3).
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Public()
  @Get()
  findAll() {
    return this.categoriesService.findAll();
  }
}

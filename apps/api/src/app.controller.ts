import { Controller, Get } from '@nestjs/common';
import { Public } from './auth/decorators/public.decorator';

@Controller()
export class AppController {
  /** Health check para Railway/Render. */
  @Public()
  @Get('health')
  health() {
    return { status: 'ok' };
  }
}

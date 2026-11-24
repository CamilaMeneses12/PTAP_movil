import { Controller, Get, Query } from '@nestjs/common';
import { ApiQuery, ApiTags } from '@nestjs/swagger';
import { Publico } from '../usuarios/decoradores.js';
import { PlantaService } from './planta.service.js';

// Información pública: la planta y los rangos normativos no son secretos.
@ApiTags('planta')
@Controller('api')
export class PlantaController {
  constructor(private readonly planta: PlantaService) {}

  @Publico()
  @Get('planta')
  informacion() {
    return this.planta.informacion();
  }

  @Publico()
  @ApiQuery({ name: 'buscar', required: false })
  @Get('parametros')
  parametros(@Query('buscar') buscar?: string) {
    return this.planta.listarParametros(buscar);
  }
}

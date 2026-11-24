import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { UsuarioActual } from '../usuarios/decoradores.js';
import type { Actor } from '../usuarios/decoradores.js';
import { CambiarEstadoDto, CrearRegistroDto } from './dto.js';
import { RegistrosService } from './registros.service.js';

// Sin @Publico: todas estas rutas exigen token. Qué ve cada quien lo decide el servicio.
@ApiTags('registros')
@ApiBearerAuth()
@Controller('api/registros')
export class RegistrosController {
  constructor(private readonly registros: RegistrosService) {}

  @Get()
  @ApiQuery({ name: 'fuera_de_rango', required: false, type: Boolean })
  listar(@UsuarioActual() actor: Actor, @Query('fuera_de_rango') fueraDeRango?: string) {
    return this.registros.listar(actor, { soloFueraDeRango: fueraDeRango === 'true' });
  }

  @Get(':codigo')
  uno(@UsuarioActual() actor: Actor, @Param('codigo') codigo: string) {
    return this.registros.uno(actor, codigo);
  }

  @Post()
  crear(@UsuarioActual() actor: Actor, @Body() datos: CrearRegistroDto) {
    return this.registros.crear(actor, datos, 'api');
  }

  @Patch(':codigo/estado')
  cambiarEstado(@UsuarioActual() actor: Actor, @Param('codigo') codigo: string, @Body() datos: CambiarEstadoDto) {
    return this.registros.cambiarEstado(actor, codigo, datos.estado);
  }
}

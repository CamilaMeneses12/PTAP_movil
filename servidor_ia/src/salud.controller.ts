import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Publico } from './usuarios/decoradores.js';

// La app consulta esta ruta para saber si el servidor está al alcance (modo automático del chat).
@ApiTags('salud')
@Controller('api/salud')
export class SaludController {
  constructor(@InjectDataSource() private readonly db: DataSource) {}

  @Publico()
  @Get()
  async salud() {
    let baseDatos = 'ok';
    try {
      await this.db.query('select 1');
    } catch {
      baseDatos = 'sin conexión';
    }
    return { estado: 'ok', base_datos: baseDatos };
  }
}

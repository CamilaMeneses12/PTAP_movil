import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RegistroValor } from './registro-valor.entity.js';
import { Registro } from './registro.entity.js';
import { RegistrosController } from './registros.controller.js';
import { RegistrosService } from './registros.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Registro, RegistroValor])],
  controllers: [RegistrosController],
  providers: [RegistrosService],
  exports: [RegistrosService],
})
export class RegistrosModule {}

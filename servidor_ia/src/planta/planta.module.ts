import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Parametro } from './parametro.entity.js';
import { PlantaController } from './planta.controller.js';
import { Planta } from './planta.entity.js';
import { PlantaService } from './planta.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Planta, Parametro])],
  controllers: [PlantaController],
  providers: [PlantaService],
  exports: [PlantaService],
})
export class PlantaModule {}

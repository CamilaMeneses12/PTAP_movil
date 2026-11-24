import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IaService } from '../ia/ia.service.js';
import { PlantaModule } from '../planta/planta.module.js';
import { RegistrosModule } from '../registros/registros.module.js';
import { ChatController } from './chat.controller.js';
import { ChatService } from './chat.service.js';
import { Mensaje } from './mensaje.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Mensaje]), PlantaModule, RegistrosModule],
  controllers: [ChatController],
  providers: [IaService, ChatService],
})
export class ChatModule {}

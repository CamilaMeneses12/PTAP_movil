import { Module } from '@nestjs/common';
import { PlantaModule } from '../planta/planta.module.js';
import { RegistrosModule } from '../registros/registros.module.js';
import { UsuariosModule } from '../usuarios/usuarios.module.js';
import { McpController } from './mcp.controller.js';

@Module({
  imports: [PlantaModule, RegistrosModule, UsuariosModule],
  controllers: [McpController],
})
export class McpModule {}

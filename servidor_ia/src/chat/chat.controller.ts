import { BadRequestException, Body, Controller, Get, HttpCode, Post, Query, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { MODOS } from '../ia/ia.service.js';
import type { Modo } from '../ia/ia.service.js';
import { UsuarioActual } from '../usuarios/decoradores.js';
import type { Actor } from '../usuarios/decoradores.js';
import { ChatService } from './chat.service.js';

const nombreSesion = (s?: string) => String(s ?? 'app').slice(0, 60);

@ApiTags('chat')
@ApiBearerAuth()
@Controller('api/chat')
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  @Get('historial')
  historial(@UsuarioActual() actor: Actor, @Query('sesion') sesion?: string) {
    return this.chat.historial(actor, nombreSesion(sesion));
  }

  // modo: 'auto' (nube y, si falla, el modelo local del servidor), 'nube' o 'local'.
  @Post()
  @HttpCode(200)
  async conversar(
    @UsuarioActual() actor: Actor,
    @Body() cuerpo: { sesion?: string; mensaje?: string; modo?: string },
    @Res() res: Response,
  ) {
    const mensaje = String(cuerpo?.mensaje ?? '').trim();
    if (!mensaje || mensaje.length > 500) {
      throw new BadRequestException('Envíe un mensaje de máximo 500 caracteres');
    }
    const modo = (cuerpo?.modo ?? 'auto') as Modo;
    if (!MODOS.includes(modo)) {
      throw new BadRequestException(`El modo debe ser uno de: ${MODOS.join(', ')}`);
    }

    // Si ningún modelo responde, NestJS contesta 503 antes de enviar nada.
    const respuesta = await this.chat.responder(actor, nombreSesion(cuerpo.sesion), mensaje, modo);
    // La app muestra qué modelo contestó.
    res.setHeader('X-Proveedor', respuesta.proveedor);
    res.setHeader('X-Modelo', respuesta.modelo);
    res.type('text/plain; charset=utf-8');
    // La respuesta se envía por partes: la app la muestra mientras se genera.
    try {
      for await (const parte of respuesta.partes) res.write(parte);
    } catch {
      res.write('\n[La respuesta se interrumpió]');
    }
    res.end();
  }
}

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Repository } from 'typeorm';
import { RAIZ } from '../config.js';
import { IaService } from '../ia/ia.service.js';
import type { MensajeModelo, Modo } from '../ia/ia.service.js';
import { PlantaService } from '../planta/planta.service.js';
import { RegistrosService } from '../registros/registros.service.js';
import type { Actor } from '../usuarios/decoradores.js';
import { Mensaje } from './mensaje.entity.js';

const PERMISOS: Record<Actor['rol'], string> = {
  operario: 'registra mediciones y consulta solo sus propios registros; puede anular uno suyo mientras está pendiente.',
  administrador: 'consulta todos los registros de la planta, los revisa, aprueba o anula, y gestiona usuarios.',
  consultor_siga: 'consulta todos los registros de la planta para auditoría, sin poder modificarlos.',
};

export interface RespuestaChat {
  proveedor: 'nube' | 'local';
  modelo: string;
  partes: AsyncGenerator<string>;
}

@Injectable()
export class ChatService {
  constructor(
    private readonly ia: IaService,
    private readonly planta: PlantaService,
    private readonly registros: RegistrosService,
    @InjectRepository(Mensaje) private readonly mensajes: Repository<Mensaje>,
  ) {}

  // El prompt se arma en cada pregunta, con los datos vigentes y SOLO los registros que esta persona puede ver.
  // Lo que no está en el prompt, el modelo no lo puede revelar.
  async sistema(actor: Actor): Promise<string> {
    const planta = await this.planta.informacion();
    const parametros = (await this.planta.listarParametros()).map((p) => `- ${p.nombre}: ${p.rango}`);
    const registros = (await this.registros.listar(actor, { limite: 8 })).map((r) => {
      const valores = r.valores
        // Se marca cada valor: los modelos pequeños se equivocan si tienen que comparar ellos mismos.
        .map(
          (v) =>
            `${v.nombre} ${v.valor} ${v.unidad} ` +
            (v.fuera_de_rango ? `(FUERA DE RANGO; rango ${v.rango})` : `(dentro de rango; rango ${v.rango})`),
        )
        .join('; ');
      const fecha = new Date(r.fecha).toLocaleString('es-CO', { timeZone: 'America/Bogota' });
      return `- ${r.codigo} (${r.tipo}, ${fecha}, de ${r.responsable}, estado ${r.estado}): ${valores}`;
    });
    const datos: Record<string, string> = {
      planta: `${planta.nombre} (${planta.ubicacion}, fuente: ${planta.fuenteAgua})`,
      norma: planta.normaReferencia,
      usuario: actor.nombre,
      rol: actor.rol,
      permisos: PERMISOS[actor.rol],
      parametros: parametros.join('\n'),
      registros: registros.join('\n') || '- Ninguno.',
    };
    const plantilla = readFileSync(join(RAIZ, 'prompts', 'chat.txt'), 'utf8');
    return plantilla.replace(/\{\{(\w+)\}\}/g, (_, clave: string) => datos[clave] ?? '');
  }

  // La memoria no está en una variable: está en la tabla mensajes y sobrevive a los reinicios.
  historial(actor: Actor, sesion: string, limite = 50) {
    return this.mensajes
      .find({
        where: { usuario: { id: actor.id }, sesion },
        order: { id: 'DESC' },
        take: limite,
        select: { id: true, rol: true, contenido: true, modelo: true, creadoEn: true },
      })
      .then((lista) => lista.reverse());
  }

  async responder(actor: Actor, sesion: string, texto: string, modo: Modo): Promise<RespuestaChat> {
    const anteriores = await this.historial(actor, sesion, 8);
    const mensajes: MensajeModelo[] = [
      { role: 'system', content: await this.sistema(actor) },
      ...anteriores.map((m) => ({ role: m.rol as 'user' | 'assistant', content: m.contenido })),
      { role: 'user', content: texto },
    ];
    const conversacion = await this.ia.conversar(mensajes, modo);
    const guardar = this.guardar.bind(this);

    async function* partes(): AsyncGenerator<string> {
      let respuesta = '';
      for await (const parte of conversacion.partes) {
        respuesta += parte;
        yield parte;
      }
      // Se guardan la pregunta y la respuesta solo si la respuesta terminó bien.
      await guardar(actor, sesion, texto, respuesta, `${conversacion.proveedor}: ${conversacion.modelo}`);
    }
    return { proveedor: conversacion.proveedor, modelo: conversacion.modelo, partes: partes() };
  }

  private async guardar(actor: Actor, sesion: string, pregunta: string, respuesta: string, modelo: string) {
    await this.mensajes.save([
      this.mensajes.create({ usuario: { id: actor.id }, sesion, rol: 'user', contenido: pregunta, modelo: null }),
      this.mensajes.create({ usuario: { id: actor.id }, sesion, rol: 'assistant', contenido: respuesta, modelo }),
    ]);
  }
}

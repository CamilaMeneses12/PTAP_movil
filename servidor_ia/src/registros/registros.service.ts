import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { Parametro } from '../planta/parametro.entity.js';
import type { TipoRegistro } from '../planta/parametro.entity.js';
import { rangoTexto, sinTildes } from '../planta/planta.service.js';
import { puedeEscribir, veTodo } from '../usuarios/decoradores.js';
import type { Actor } from '../usuarios/decoradores.js';
import { RegistroValor } from './registro-valor.entity.js';
import { Registro } from './registro.entity.js';
import type { Estado } from './registro.entity.js';

export interface NuevoRegistro {
  tipo: TipoRegistro;
  valores: { parametro: string; valor: number }[];
  observacion?: string;
}

// Cambios de estado permitidos. Lo que no está aquí, no se puede hacer.
const SIGUIENTE: Record<Estado, Estado[]> = {
  pendiente: ['revisado', 'anulado'],
  revisado: ['aprobado', 'anulado'],
  aprobado: [],
  anulado: [],
};

export const codigo = (id: number) => 'R-' + String(id).padStart(4, '0');

const fuera = (valor: number, min: number | null, max: number | null) =>
  (min !== null && valor < min) || (max !== null && valor > max);

// Todas las reglas de los registros, en un solo lugar. Las cumple quien entre por cualquier puerta
// (la app, la API o un asistente por MCP).
@Injectable()
export class RegistrosService {
  constructor(
    @InjectRepository(Registro) private readonly registros: Repository<Registro>,
    @InjectDataSource() private readonly db: DataSource,
  ) {}

  async listar(actor: Actor, opciones: { limite?: number; soloFueraDeRango?: boolean } = {}) {
    const lista = await this.registros.find({
      where: {
        ...(veTodo(actor) ? {} : { usuario: { id: actor.id } }),
        ...(opciones.soloFueraDeRango ? { fueraDeRango: true } : {}),
      },
      relations: { usuario: true, valores: { parametro: true } },
      order: { id: 'DESC' },
      take: Math.min(opciones.limite ?? 20, 100),
    });
    return lista.map((r) => this.aRespuesta(r));
  }

  async uno(actor: Actor, cod: string) {
    return this.aRespuesta(await this.buscar(actor, cod));
  }

  async crear(actor: Actor, datos: NuevoRegistro, origen: 'api' | 'mcp') {
    if (!puedeEscribir(actor)) {
      throw new ForbiddenException('El consultor SIGA solo puede consultar, no registrar');
    }
    if (!Array.isArray(datos?.valores) || datos.valores.length === 0) {
      throw new BadRequestException('El registro no tiene valores');
    }

    // Todo o nada: si algo falla, no queda un registro a medias en la base.
    const id = await this.db.transaction(async (tx) => {
      const catalogo = await tx.find(Parametro, { where: { activo: true, tipo: datos.tipo } });
      const valores = datos.valores.map((v) => {
        const buscado = sinTildes(String(v?.parametro ?? ''));
        const parametro = catalogo.find((p) => p.id === buscado || sinTildes(p.nombre) === buscado);
        if (!parametro) {
          throw new BadRequestException(
            `El parámetro "${v?.parametro}" no existe para registros de ${datos.tipo}. Consulte los parámetros.`,
          );
        }
        if (typeof v.valor !== 'number' || !Number.isFinite(v.valor)) {
          throw new BadRequestException(`El valor de ${parametro.nombre} debe ser un número`);
        }
        // Se permite guardar fuera de rango (igual que en la app): solo se marca.
        return tx.create(RegistroValor, {
          parametro,
          valor: v.valor,
          minimoVigente: parametro.minimo,
          maximoVigente: parametro.maximo,
          fueraDeRango: fuera(v.valor, parametro.minimo, parametro.maximo),
        });
      });
      const registro = await tx.save(
        tx.create(Registro, {
          usuario: { id: actor.id },
          tipo: datos.tipo,
          valores,
          origen,
          observacion: String(datos.observacion ?? '').trim().slice(0, 300),
          fueraDeRango: valores.some((v) => v.fueraDeRango),
        }),
      );
      return registro.id;
    });
    return this.uno(actor, codigo(id));
  }

  async cambiarEstado(actor: Actor, cod: string, nuevo: Estado) {
    if (!puedeEscribir(actor)) {
      throw new ForbiddenException('El consultor SIGA solo puede consultar, no modificar registros');
    }
    const registro = await this.buscar(actor, cod);
    // Un operario solo puede anular su propio registro mientras está pendiente.
    if (actor.rol === 'operario' && !(nuevo === 'anulado' && registro.estado === 'pendiente')) {
      throw new ForbiddenException('Un operario solo puede anular un registro suyo, y solo mientras está pendiente');
    }
    if (!SIGUIENTE[registro.estado].includes(nuevo)) {
      throw new BadRequestException(`El registro ${codigo(registro.id)} está ${registro.estado}: no puede pasar a ${nuevo}`);
    }
    await this.registros.update(registro.id, { estado: nuevo });
    return this.uno(actor, cod);
  }

  // Un operario que pregunta por el registro de otro recibe 404, no 403: así no sabe que existe.
  private async buscar(actor: Actor, cod: string): Promise<Registro> {
    const numero = Number(/^R-?(\d{1,9})$/i.exec(String(cod).trim())?.[1]);
    const registro = numero
      ? await this.registros.findOne({ where: { id: numero }, relations: { usuario: true, valores: { parametro: true } } })
      : null;
    if (!registro || (!veTodo(actor) && registro.usuario.id !== actor.id)) {
      throw new NotFoundException(`No existe el registro ${cod}`);
    }
    return registro;
  }

  private aRespuesta(r: Registro) {
    return {
      codigo: codigo(r.id),
      fecha: r.creadoEn,
      tipo: r.tipo,
      origen: r.origen,
      responsable: r.usuario.nombre,
      valores: r.valores.map((v) => ({
        parametro: v.parametro.id,
        nombre: v.parametro.nombre,
        valor: v.valor,
        unidad: v.parametro.unidad,
        rango: rangoTexto({ minimo: v.minimoVigente, maximo: v.maximoVigente, unidad: v.parametro.unidad }),
        fuera_de_rango: v.fueraDeRango,
      })),
      observacion: r.observacion,
      fuera_de_rango: r.fueraDeRango,
      estado: r.estado,
    };
  }
}

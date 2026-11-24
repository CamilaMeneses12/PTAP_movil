import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Parametro } from './parametro.entity.js';
import { Planta } from './planta.entity.js';

export const sinTildes = (texto: string) =>
  texto.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();

// Texto legible del rango: "6,5–9 pH", "máx. 2 NTU", "mín. 40 %".
export function rangoTexto(p: Pick<Parametro, 'minimo' | 'maximo' | 'unidad'>): string {
  const f = (n: number) => n.toLocaleString('es-CO');
  if (p.minimo !== null && p.maximo !== null && p.minimo > 0) return `${f(p.minimo)}–${f(p.maximo)} ${p.unidad}`;
  if (p.maximo !== null) return `máx. ${f(p.maximo)} ${p.unidad}`;
  if (p.minimo !== null) return `mín. ${f(p.minimo)} ${p.unidad}`;
  return 'sin límite';
}

@Injectable()
export class PlantaService {
  constructor(
    @InjectRepository(Planta) private readonly plantas: Repository<Planta>,
    @InjectRepository(Parametro) private readonly parametros: Repository<Parametro>,
  ) {}

  informacion() {
    return this.plantas.findOneByOrFail({ id: 1 });
  }

  async listarParametros(buscar?: string) {
    const todos = await this.parametros.find({ where: { activo: true }, order: { tipo: 'ASC', id: 'ASC' } });
    const texto = sinTildes(buscar ?? '');
    return todos
      .filter((p) => !texto || sinTildes(p.nombre).includes(texto) || p.id.includes(texto))
      .map((p) => ({ ...p, rango: rangoTexto(p) }));
  }
}

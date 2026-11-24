import { Column, Entity, PrimaryColumn } from 'typeorm';

export const TIPOS_REGISTRO = ['fisicoquimico', 'medidores', 'caudal'] as const;
export type TipoRegistro = (typeof TIPOS_REGISTRO)[number];

// Parámetro que se mide en la planta, con su rango normativo vigente.
@Entity('parametros')
export class Parametro {
  // Un texto corto y legible: ph_tratada, cloro_residual…
  @PrimaryColumn({ length: 40 })
  id: string;

  @Column({ length: 100 })
  nombre: string;

  @Column({ length: 20 })
  unidad: string;

  @Column({ type: 'enum', enum: TIPOS_REGISTRO })
  tipo: TipoRegistro;

  // null = sin límite por ese lado (la turbidez solo tiene máximo).
  @Column({ type: 'numeric', precision: 10, scale: 3, nullable: true, transformer: decimal() })
  minimo: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, nullable: true, transformer: decimal() })
  maximo: number | null;

  @Column({ default: true })
  activo: boolean;
}

// PostgreSQL devuelve los numeric como texto: se convierten a número al leer.
export function decimal() {
  return {
    to: (v: number | null) => v,
    from: (v: string | null) => (v === null ? null : Number(v)),
  };
}

import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import type { Relation } from 'typeorm';
import { TIPOS_REGISTRO } from '../planta/parametro.entity.js';
import type { TipoRegistro } from '../planta/parametro.entity.js';
import { Usuario } from '../usuarios/usuario.entity.js';
import { RegistroValor } from './registro-valor.entity.js';

export const ESTADOS = ['pendiente', 'revisado', 'aprobado', 'anulado'] as const;
export type Estado = (typeof ESTADOS)[number];

// Un registro de campo (análisis fisicoquímico, lectura de medidores o aforo de caudal).
@Entity('registros')
export class Registro {
  @PrimaryGeneratedColumn()
  id: number;

  // El autor sale del token, nunca del cuerpo de la petición.
  // Relation<> evita un error de importación circular con los módulos ES.
  @ManyToOne(() => Usuario, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'usuario_id' })
  usuario: Relation<Usuario>;

  @OneToMany(() => RegistroValor, (valor) => valor.registro, { cascade: ['insert'] })
  valores: Relation<RegistroValor[]>;

  @Column({ type: 'enum', enum: TIPOS_REGISTRO })
  tipo: TipoRegistro;

  // Por dónde entró: la API (app), o un asistente por MCP.
  @Column({ length: 10 })
  origen: string;

  @Column({ length: 300, default: '' })
  observacion: string;

  @Column({ name: 'fuera_de_rango', default: false })
  fueraDeRango: boolean;

  @Column({ type: 'enum', enum: ESTADOS, default: 'pendiente' })
  estado: Estado;

  @CreateDateColumn({ name: 'creado_en', type: 'timestamptz' })
  creadoEn: Date;
}

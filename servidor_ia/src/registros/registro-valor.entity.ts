import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import type { Relation } from 'typeorm';
import { decimal, Parametro } from '../planta/parametro.entity.js';
import { Registro } from './registro.entity.js';

// Un valor medido dentro de un registro.
@Entity('registro_valores')
export class RegistroValor {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Registro, (registro) => registro.valores, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'registro_id' })
  registro: Relation<Registro>;

  @ManyToOne(() => Parametro, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'parametro_id' })
  parametro: Relation<Parametro>;

  @Column({ type: 'numeric', precision: 12, scale: 4, transformer: decimal() })
  valor: number;

  // El rango se copia al registro: si mañana cambia la norma, el registro conserva la que aplicaba.
  @Column({ name: 'minimo_vigente', type: 'numeric', precision: 10, scale: 3, nullable: true, transformer: decimal() })
  minimoVigente: number | null;

  @Column({ name: 'maximo_vigente', type: 'numeric', precision: 10, scale: 3, nullable: true, transformer: decimal() })
  maximoVigente: number | null;

  @Column({ name: 'fuera_de_rango', default: false })
  fueraDeRango: boolean;
}

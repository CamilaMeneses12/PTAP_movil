import { Column, Entity, PrimaryColumn } from 'typeorm';

// La planta de tratamiento (una sola fila).
@Entity('planta')
export class Planta {
  @PrimaryColumn({ type: 'int' })
  id: number;

  @Column({ length: 120 })
  nombre: string;

  @Column({ length: 120 })
  ubicacion: string;

  @Column({ name: 'fuente_agua', length: 120 })
  fuenteAgua: string;

  @Column({ name: 'norma_referencia', length: 160 })
  normaReferencia: string;
}

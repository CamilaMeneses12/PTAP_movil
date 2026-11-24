import 'reflect-metadata';
import { requerida, opcional } from '../config.js';
import { Parametro } from '../planta/parametro.entity.js';
import { Planta } from '../planta/planta.entity.js';
import { cifrarClave } from '../usuarios/claves.js';
import { Usuario } from '../usuarios/usuario.entity.js';
import fuente from './fuente.js';

// Carga la planta, los parámetros con sus rangos (Res. 2115 de 2007 y control operativo)
// y el primer administrador. Se puede ejecutar varias veces.
const PARAMETROS: Omit<Parametro, 'activo'>[] = [
  { id: 'ph_cruda', nombre: 'pH agua cruda', unidad: 'pH', tipo: 'fisicoquimico', minimo: 5, maximo: 9 },
  { id: 'turbidez_cruda', nombre: 'Turbidez agua cruda', unidad: 'UJT', tipo: 'fisicoquimico', minimo: 0, maximo: 10 },
  { id: 'color_cruda', nombre: 'Color agua cruda', unidad: 'UPC', tipo: 'fisicoquimico', minimo: 0, maximo: 20 },
  { id: 'ph_tratada', nombre: 'pH agua tratada', unidad: 'pH', tipo: 'fisicoquimico', minimo: 6.5, maximo: 9 },
  { id: 'turbidez_tratada', nombre: 'Turbidez agua tratada', unidad: 'NTU', tipo: 'fisicoquimico', minimo: 0, maximo: 2 },
  { id: 'color_aparente', nombre: 'Color aparente', unidad: 'UPC', tipo: 'fisicoquimico', minimo: 0, maximo: 15 },
  { id: 'cloro_residual', nombre: 'Cloro residual libre', unidad: 'mg/L', tipo: 'fisicoquimico', minimo: 0.3, maximo: 2 },
  { id: 'caudal_entrada', nombre: 'Caudal de entrada', unidad: 'L/s', tipo: 'caudal', minimo: 110, maximo: 140 },
  { id: 'caudal_salida', nombre: 'Caudal de salida', unidad: 'L/s', tipo: 'caudal', minimo: 105, maximo: 135 },
  { id: 'caudal_quebrada', nombre: 'Caudal quebrada La Seca', unidad: 'L/s', tipo: 'caudal', minimo: 10, maximo: null },
  { id: 'consumo_micromedidores', nombre: 'Consumo micromedidores', unidad: 'm³', tipo: 'medidores', minimo: 0, maximo: null },
  { id: 'consumo_macromedidor', nombre: 'Consumo macromedidor', unidad: 'm³', tipo: 'medidores', minimo: 0, maximo: null },
  { id: 'agua_no_registrada', nombre: 'Agua no registrada', unidad: 'm³', tipo: 'medidores', minimo: null, maximo: 5 },
];

await fuente.initialize();
try {
  await fuente.getRepository(Planta).save({
    id: 1,
    nombre: 'PTAP Villa Clara',
    ubicacion: 'SENA, Centro de Gestión Agroempresarial',
    fuenteAgua: 'Quebrada La Seca',
    normaReferencia: 'Resolución 2115 de 2007 y formato DO-F-070',
  });
  await fuente.getRepository(Parametro).save(PARAMETROS.map((p) => ({ ...p, activo: true })));

  const usuarios = fuente.getRepository(Usuario);
  const correo = opcional('ADMIN_CORREO', 'admin@ptap.test').toLowerCase();
  if (!(await usuarios.existsBy({ correo }))) {
    const clave = requerida('ADMIN_CLAVE');
    if (clave.length < 10 || !/[a-zA-Z]/.test(clave) || !/[0-9]/.test(clave)) {
      throw new Error('ADMIN_CLAVE debe tener 10 o más caracteres, con letras y números');
    }
    await usuarios.save(usuarios.create({ nombre: 'Administrador', correo, claveHash: await cifrarClave(clave), rol: 'administrador' }));
  }
  console.log(`Semilla cargada: 1 planta, ${PARAMETROS.length} parámetros y el administrador ${correo}`);
} finally {
  await fuente.destroy();
}

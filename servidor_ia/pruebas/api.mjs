// Uso: node pruebas/api.mjs METODO /ruta [clave=valor ... | archivo.json] [--sin-token]
// Ejemplos:
//   node pruebas/api.mjs GET /api/registros
//   node pruebas/api.mjs PATCH /api/registros/R-0001/estado estado=revisado
//   node pruebas/api.mjs POST /api/registros registro.json
import { cuerpoDe, leerToken, llamar, mostrar } from './comun.mjs';

const argumentos = process.argv.slice(2);
const sinToken = argumentos.includes('--sin-token');
const [metodo, ruta, ...resto] = argumentos.filter((a) => a !== '--sin-token');
mostrar(await llamar(metodo.toUpperCase(), ruta, { cuerpo: cuerpoDe(resto), token: sinToken ? '' : leerToken('web') }));

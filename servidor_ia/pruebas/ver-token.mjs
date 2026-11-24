// Muestra lo que lleva por dentro el token web guardado (va firmado, no cifrado).
// Uso: node pruebas/ver-token.mjs [web|mcp]
import { leerToken } from './comun.mjs';

const token = leerToken(process.argv[2] ?? 'web');
if (!token) {
  console.log('No hay token guardado. Entre primero con node pruebas/entrar.mjs');
  process.exit(1);
}
const [cabecera, carga, firma] = token.split('.');
const leer = (parte) => JSON.parse(Buffer.from(parte, 'base64url').toString('utf8'));
const datos = leer(carga);
const fecha = (s) => new Date(s * 1000).toLocaleString('es-CO', { timeZone: 'America/Bogota' });
console.log(`Cabecera: ${JSON.stringify(leer(cabecera))}`);
console.log(`Carga:    ${JSON.stringify(datos)}`);
console.log(`Emitido: ${fecha(datos.iat)}  |  Vence: ${fecha(datos.exp)}`);
console.log(`Firma:    ${firma.slice(0, 12)}… (solo la puede producir quien conoce JWT_SECRETO)`);

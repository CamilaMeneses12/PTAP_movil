import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// Carpeta servidor_ia (este archivo queda en dist/config.js al compilar).
export const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..');

// Carga servidor_ia/.env sin sobrescribir variables que ya vengan del sistema.
const archivoEnv = join(RAIZ, '.env');
if (existsSync(archivoEnv)) {
  for (const linea of readFileSync(archivoEnv, 'utf8').split(/\r?\n/)) {
    const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/.exec(linea);
    if (!m || linea.trimStart().startsWith('#')) continue;
    const [, clave, valor] = m;
    if (process.env[clave] === undefined) {
      process.env[clave] = valor.replace(/^["']|["']$/g, '');
    }
  }
}

// Una variable obligatoria: si falta, la API no arranca y dice cuál es.
export function requerida(nombre: string): string {
  const valor = process.env[nombre];
  if (!valor) {
    throw new Error(`Falta la variable ${nombre} en el archivo servidor_ia/.env`);
  }
  return valor;
}

export function opcional(nombre: string, porDefecto = ''): string {
  return process.env[nombre] || porDefecto;
}

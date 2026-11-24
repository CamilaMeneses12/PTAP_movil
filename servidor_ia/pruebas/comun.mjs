// Utilidades compartidas por los programas de prueba (evitan los problemas de comillas de Windows).
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const CARPETA = dirname(fileURLToPath(import.meta.url));
export const API = process.env.API ?? 'http://localhost:3100';
const archivoToken = (tipo) => join(CARPETA, `.token-${tipo}`);

export const leerToken = (tipo = 'web') =>
  existsSync(archivoToken(tipo)) ? readFileSync(archivoToken(tipo), 'utf8').trim() : '';
export const guardarToken = (tipo, token) => writeFileSync(archivoToken(tipo), token);

// Llama la API y devuelve { estado, datos }.
export async function llamar(metodo, ruta, { cuerpo, token } = {}) {
  // Git Bash convierte "/api/..." en "C:/Program Files/Git/api/...": se deshace.
  ruta = ruta.replace(/^[A-Za-z]:\/Program Files\/Git/, '');
  const respuesta = await fetch(API + ruta, {
    method: metodo,
    headers: {
      ...(cuerpo !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: cuerpo !== undefined ? JSON.stringify(cuerpo) : undefined,
  });
  const texto = await respuesta.text();
  let datos = texto;
  try {
    datos = JSON.parse(texto);
  } catch {}
  return { estado: respuesta.status, datos, encabezados: respuesta.headers };
}

export const mostrar = ({ estado, datos }) => {
  console.log(`HTTP ${estado}`);
  console.log(typeof datos === 'string' ? datos : JSON.stringify(datos, null, 2));
};

// clave=valor (números y true/false se convierten) o un archivo .json de la carpeta pruebas.
export function cuerpoDe(argumentos) {
  if (argumentos.length === 1 && argumentos[0].endsWith('.json')) {
    const ruta = existsSync(argumentos[0]) ? argumentos[0] : join(CARPETA, argumentos[0]);
    return JSON.parse(readFileSync(ruta, 'utf8'));
  }
  if (!argumentos.length) return undefined;
  return Object.fromEntries(
    argumentos.map((a) => {
      const [clave, ...resto] = a.split('=');
      const valor = resto.join('=');
      if (valor === 'true' || valor === 'false') return [clave, valor === 'true'];
      if (valor !== '' && !Number.isNaN(Number(valor))) return [clave, Number(valor)];
      return [clave, valor];
    }),
  );
}

// Uso: node pruebas/chat.mjs "pregunta" [auto|nube|local]
// Conversa con el Asistente PTAP en la sesión "terminal" y muestra qué modelo respondió.
import { API, leerToken } from './comun.mjs';

const [mensaje, modo = 'auto'] = process.argv.slice(2);
const inicio = Date.now();
const respuesta = await fetch(`${API}/api/chat`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${leerToken('web')}` },
  body: JSON.stringify({ sesion: 'terminal', mensaje, modo }),
});

if (!respuesta.ok) {
  console.log(`HTTP ${respuesta.status}: ${await respuesta.text()}`);
  process.exitCode = 1;
} else {
  console.log(`[${respuesta.headers.get('x-proveedor')}: ${respuesta.headers.get('x-modelo')}]`);
  const decodificador = new TextDecoder();
  for await (const parte of respuesta.body) process.stdout.write(decodificador.decode(parte, { stream: true }));
  console.log(`\n(${((Date.now() - inicio) / 1000).toFixed(1)} s)`);
}

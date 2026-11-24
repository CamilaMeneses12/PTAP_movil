// Uso: node pruebas/entrar.mjs correo clave
// Guarda dos tokens en archivos ocultos de esta carpeta: el web (8 h) y el mcp (7 días).
import { guardarToken, llamar } from './comun.mjs';

const [correo, clave] = process.argv.slice(2);
const r = await llamar('POST', '/api/auth/entrar', { cuerpo: { correo, clave } });
if (r.estado !== 200) {
  console.log(`HTTP ${r.estado}: ${r.datos?.message ?? JSON.stringify(r.datos)}`);
  process.exitCode = 1;
} else {
  guardarToken('web', r.datos.token);
  const mcp = await llamar('POST', '/api/auth/token-mcp', { token: r.datos.token });
  guardarToken('mcp', mcp.datos.token);
  console.log(`Sesión iniciada: ${r.datos.usuario.nombre} (${r.datos.usuario.rol}).`);
  console.log('Tokens guardados en pruebas/.token-web (8 horas) y pruebas/.token-mcp (7 días).');
}

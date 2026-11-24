// Banco de pruebas de acceso del Asistente PTAP.
// Uso (con la API en ejecución): node pruebas/acceso.mjs
//
// En cada corrida crea tres usuarios nuevos: Ana y Beto (operarios) y Carla, a quien el administrador
// del .env vuelve consultora SIGA. Ejecuta pruebas sobre la API y el servidor MCP; cada una dice qué
// respuesta espera y cuál obtuvo. El detalle queda en pruebas/resultados-acceso.csv.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { CARPETA, llamar } from './comun.mjs';
import { conectarMcp, textoDe } from './mcp-cliente.mjs';

const env = Object.fromEntries(
  readFileSync(join(CARPETA, '..', '.env'), 'utf8')
    .split(/\r?\n/)
    .map((l) => /^([A-Z_]+)=(.*)$/.exec(l))
    .filter(Boolean)
    .map((m) => [m[1], m[2]]),
);
const CLAVE = 'AguaClara2026';
const sello = Date.now().toString(36);
const resultados = [];

function anotar(grupo, descripcion, esperado, obtenido) {
  const ok = String(esperado) === String(obtenido);
  resultados.push({ ok, grupo, descripcion, esperado, obtenido });
  console.log(`${ok ? 'OK ' : 'MAL'}  ${grupo.padEnd(9)} ${descripcion.padEnd(70)} [${esperado}/${obtenido}]`);
}

async function probar(grupo, descripcion, esperado, metodo, ruta, opciones) {
  const r = await llamar(metodo, ruta, opciones);
  anotar(grupo, descripcion, esperado, r.estado);
  return r;
}

async function nuevo(nombre) {
  const correo = `${nombre.toLowerCase()}.${sello}@ptap.test`;
  await llamar('POST', '/api/auth/registro', { cuerpo: { nombre, correo, clave: CLAVE } });
  const r = await llamar('POST', '/api/auth/entrar', { cuerpo: { correo, clave: CLAVE } });
  return { ...r.datos.usuario, token: r.datos.token };
}

const tokenMcp = async (token) => (await llamar('POST', '/api/auth/token-mcp', { token })).datos.token;

// ---------------------------------------------------------------- preparación
const ana = await nuevo('Ana');
const beto = await nuevo('Beto');
const carla = await nuevo('Carla');
const admin = (await llamar('POST', '/api/auth/entrar', { cuerpo: { correo: env.ADMIN_CORREO, clave: env.ADMIN_CLAVE } })).datos;
const registro = JSON.parse(readFileSync(join(CARPETA, 'registro.json'), 'utf8'));

// ---------------------------------------------------------------- público e identidad
await probar('público', 'GET /api/salud responde sin token', 200, 'GET', '/api/salud');
await probar('público', 'GET /api/parametros sin token (rangos normativos públicos)', 200, 'GET', '/api/parametros');
await probar('admin', 'El administrador vuelve consultora SIGA a Carla', 200, 'PATCH', `/api/usuarios/${carla.id}/rol`, {
  token: admin.token,
  cuerpo: { rol: 'consultor_siga' },
});
await probar('identidad', 'GET /api/registros sin token', 401, 'GET', '/api/registros');
await probar('identidad', 'GET /api/auth/yo sin token', 401, 'GET', '/api/auth/yo');
await probar('identidad', 'GET /api/auth/yo con un token alterado', 401, 'GET', '/api/auth/yo', { token: ana.token.slice(0, -3) + 'abc' });
const mcpAna = await tokenMcp(ana.token);
await probar('identidad', 'El token MCP no sirve en la API web', 401, 'GET', '/api/auth/yo', { token: mcpAna });
await probar('identidad', 'Entrar con clave errada', 401, 'POST', '/api/auth/entrar', { cuerpo: { correo: `ana.${sello}@ptap.test`, clave: 'otra-clave-1' } });
await probar('identidad', 'Entrar con un correo que no existe', 401, 'POST', '/api/auth/entrar', { cuerpo: { correo: `nadie.${sello}@ptap.test`, clave: CLAVE } });
await probar('validación', 'Registrarse enviando "rol": "administrador"', 400, 'POST', '/api/auth/registro', {
  cuerpo: { nombre: 'Intruso', correo: `intruso.${sello}@ptap.test`, clave: CLAVE, rol: 'administrador' },
});
await probar('validación', 'Registrarse con una clave corta', 400, 'POST', '/api/auth/registro', {
  cuerpo: { nombre: 'Eva', correo: `eva.${sello}@ptap.test`, clave: 'corta1' },
});
await probar('validación', 'Registrarse con un correo ya usado', 409, 'POST', '/api/auth/registro', {
  cuerpo: { nombre: 'Ana', correo: `ana.${sello}@ptap.test`, clave: CLAVE },
});

// ---------------------------------------------------------------- roles
await probar('rol', 'Ana (operaria) lista los usuarios', 403, 'GET', '/api/usuarios', { token: ana.token });
await probar('rol', 'Carla (consultora) lista los usuarios', 403, 'GET', '/api/usuarios', { token: carla.token });
await probar('rol', 'El administrador lista los usuarios', 200, 'GET', '/api/usuarios', { token: admin.token });
await probar('rol', 'Ana intenta cambiar su propio rol', 403, 'PATCH', `/api/usuarios/${ana.id}/rol`, {
  token: ana.token,
  cuerpo: { rol: 'administrador' },
});

// ---------------------------------------------------------------- registros
const creado = await probar('registros', 'Ana registra una medición', 201, 'POST', '/api/registros', { token: ana.token, cuerpo: registro });
const cod = creado.datos.codigo;
anotar('registros', 'El responsable del registro sale del token (Ana)', 'Ana', creado.datos.responsable);
anotar('registros', 'El cloro 0,2 queda marcado fuera de rango (se guarda igual)', true, creado.datos.fuera_de_rango);
await probar('registros', 'Ana registra a nombre de otra persona ("usuario")', 400, 'POST', '/api/registros', {
  token: ana.token,
  cuerpo: { ...registro, usuario: beto.id },
});
await probar('registros', 'Ana registra un parámetro que no existe', 400, 'POST', '/api/registros', {
  token: ana.token,
  cuerpo: { tipo: 'fisicoquimico', valores: [{ parametro: 'oro', valor: 1 }] },
});
await probar('registros', 'Ana consulta su registro', 200, 'GET', `/api/registros/${cod}`, { token: ana.token });
await probar('registros', 'Beto consulta el registro de Ana (no debe saber que existe)', 404, 'GET', `/api/registros/${cod}`, { token: beto.token });
const listaBeto = await probar('registros', 'Beto lista sus registros', 200, 'GET', '/api/registros', { token: beto.token });
anotar('registros', 'La lista de Beto no incluye el registro de Ana', false, listaBeto.datos.some((r) => r.codigo === cod));
await probar('registros', 'Carla (consultora) consulta el registro de Ana', 200, 'GET', `/api/registros/${cod}`, { token: carla.token });
await probar('registros', 'Carla (consultora) intenta registrar', 403, 'POST', '/api/registros', { token: carla.token, cuerpo: registro });
await probar('registros', 'Carla (consultora) intenta anular el registro', 403, 'PATCH', `/api/registros/${cod}/estado`, {
  token: carla.token,
  cuerpo: { estado: 'anulado' },
});
await probar('registros', 'Ana intenta revisar su propio registro', 403, 'PATCH', `/api/registros/${cod}/estado`, {
  token: ana.token,
  cuerpo: { estado: 'revisado' },
});
await probar('registros', 'Beto intenta anular el registro de Ana', 404, 'PATCH', `/api/registros/${cod}/estado`, {
  token: beto.token,
  cuerpo: { estado: 'anulado' },
});
await probar('registros', 'El administrador salta de pendiente a aprobado', 400, 'PATCH', `/api/registros/${cod}/estado`, {
  token: admin.token,
  cuerpo: { estado: 'aprobado' },
});
await probar('registros', 'El administrador revisa el registro', 200, 'PATCH', `/api/registros/${cod}/estado`, {
  token: admin.token,
  cuerpo: { estado: 'revisado' },
});
await probar('registros', 'Ana intenta anular un registro ya revisado', 403, 'PATCH', `/api/registros/${cod}/estado`, {
  token: ana.token,
  cuerpo: { estado: 'anulado' },
});
await probar('registros', 'El administrador aprueba el registro', 200, 'PATCH', `/api/registros/${cod}/estado`, {
  token: admin.token,
  cuerpo: { estado: 'aprobado' },
});
const otro = await llamar('POST', '/api/registros', { token: ana.token, cuerpo: registro });
await probar('registros', 'Ana anula un registro suyo pendiente', 200, 'PATCH', `/api/registros/${otro.datos.codigo}/estado`, {
  token: ana.token,
  cuerpo: { estado: 'anulado' },
});
await probar('chat', 'El historial del chat exige token', 401, 'GET', '/api/chat/historial');
await probar('chat', 'Un mensaje vacío al chat', 400, 'POST', '/api/chat', { token: ana.token, cuerpo: { mensaje: '' } });

// ---------------------------------------------------------------- MCP
async function herramientas(token) {
  const cliente = await conectarMcp(token);
  const { tools } = await cliente.listTools();
  await cliente.close();
  return tools.map((t) => t.name);
}
async function usar(token, nombre, argumentos) {
  const cliente = await conectarMcp(token);
  try {
    const r = await cliente.callTool({ name: nombre, arguments: argumentos });
    return { error: r.isError === true, texto: textoDe(r) };
  } catch (error) {
    return { error: true, texto: error.message };
  } finally {
    await cliente.close();
  }
}

const mcpBeto = await tokenMcp(beto.token);
const mcpCarla = await tokenMcp(carla.token);
const mcpAdmin = await tokenMcp(admin.token);
const sinToken = await llamar('POST', '/mcp', { cuerpo: {} });
anotar('mcp', 'POST /mcp sin token', 401, sinToken.estado);
anotar('mcp', 'La respuesta 401 trae WWW-Authenticate: Bearer', 'Bearer', sinToken.encabezados.get('www-authenticate'));
anotar('mcp', 'El token web no sirve en el servidor MCP', 401, (await llamar('POST', '/mcp', { token: ana.token, cuerpo: {} })).estado);
anotar('mcp', 'Ana (operaria) ve 5 herramientas', 5, (await herramientas(mcpAna)).length);
anotar('mcp', 'Carla (consultora) ve 3 herramientas', 3, (await herramientas(mcpCarla)).length);
anotar('mcp', 'El administrador ve 6 herramientas', 6, (await herramientas(mcpAdmin)).length);
anotar('mcp', 'Ana llama cambiar_estado_registro a la fuerza', 'error', (await usar(mcpAna, 'cambiar_estado_registro', { codigo: cod, estado: 'revisado' })).error ? 'error' : 'ok');
anotar('mcp', 'Carla llama registrar_medicion a la fuerza', 'error', (await usar(mcpCarla, 'registrar_medicion', registro)).error ? 'error' : 'ok');
const porMcp = await usar(mcpBeto, 'registrar_medicion', registro);
anotar('mcp', 'Beto registra por MCP y queda como responsable', 'Beto', porMcp.error ? 'error' : JSON.parse(porMcp.texto).responsable);
anotar('mcp', 'Beto consulta por MCP el registro de Ana', 'error', (await usar(mcpBeto, 'consultar_registros', { codigo: cod })).error ? 'error' : 'ok');
anotar('mcp', 'Carla consulta por MCP el registro de Ana', 'ok', (await usar(mcpCarla, 'consultar_registros', { codigo: cod })).error ? 'error' : 'ok');
// Cambio de rol con efecto inmediato: el rol no va en el token, se consulta en cada petición.
await llamar('PATCH', `/api/usuarios/${carla.id}/rol`, { token: admin.token, cuerpo: { rol: 'operario' } });
anotar('rol', 'Con el mismo token MCP, Carla (ahora operaria) ve 5 herramientas', 5, (await herramientas(mcpCarla)).length);

// ---------------------------------------------------------------- límite de intentos
let bloqueado = 0;
for (let i = 0; i < 15 && !bloqueado; i++) {
  const r = await llamar('POST', '/api/auth/entrar', { cuerpo: { correo: `ana.${sello}@ptap.test`, clave: 'otra-clave-1' } });
  if (r.estado === 429) bloqueado = 429;
}
anotar('límite', 'Muchos intentos de entrar seguidos terminan en 429', 429, bloqueado || 'sin bloqueo');

// ---------------------------------------------------------------- resumen
const correctas = resultados.filter((r) => r.ok).length;
writeFileSync(
  join(CARPETA, 'resultados-acceso.csv'),
  '﻿resultado;grupo;prueba;esperado;obtenido\n' +
    resultados.map((r) => [r.ok ? 'OK' : 'MAL', r.grupo, r.descripcion, r.esperado, r.obtenido].join(';')).join('\n'),
);
console.log(`\nRESUMEN: ${correctas} de ${resultados.length} pruebas de acceso correctas`);
console.log('Detalle en pruebas/resultados-acceso.csv');
console.log('Nota: durante un minuto, la ruta de entrar queda bloqueada para este equipo.');
if (correctas !== resultados.length) process.exitCode = 1;

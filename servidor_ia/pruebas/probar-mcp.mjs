// Uso:
//   node pruebas/probar-mcp.mjs                                   lista las herramientas del usuario
//   node pruebas/probar-mcp.mjs consultar_registros               llama una herramienta
//   node pruebas/probar-mcp.mjs registrar_medicion registro.json  con argumentos de un archivo
//   node pruebas/probar-mcp.mjs cambiar_estado_registro codigo=R-0001 estado=revisado
// Usa el token de pruebas/.token-mcp (el que guarda entrar.mjs).
import { cuerpoDe, leerToken } from './comun.mjs';
import { conectarMcp, textoDe } from './mcp-cliente.mjs';

const [herramienta, ...resto] = process.argv.slice(2);
const inicio = Date.now();
let cliente;
try {
  cliente = await conectarMcp(leerToken('mcp'));
} catch (error) {
  console.log(`No fue posible conectar: ${error.message}`);
  process.exit(1);
}
const servidor = cliente.getServerVersion();
console.log(`Conectado a "${servidor?.name}" ${servidor?.version}.`);

if (!herramienta) {
  const { tools } = await cliente.listTools();
  console.log(`Herramientas: ${tools.length}`);
  for (const t of tools) console.log(`- ${t.name} (${t.annotations?.readOnlyHint ? 'solo lectura' : 'escribe'})`);
} else {
  try {
    const r = await cliente.callTool({ name: herramienta, arguments: cuerpoDe(resto) ?? {} });
    console.log(r.isError ? `No fue posible: ${textoDe(r)}` : textoDe(r));
  } catch (error) {
    console.log(`No fue posible: ${error.message}`);
  }
}
console.log(`(${Date.now() - inicio} ms)`);
await cliente.close();

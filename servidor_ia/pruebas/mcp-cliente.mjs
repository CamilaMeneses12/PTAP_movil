// Cliente MCP de prueba: se conecta a /mcp con un token y devuelve el cliente conectado.
import { Client, StreamableHTTPClientTransport } from '@modelcontextprotocol/client';
import { API } from './comun.mjs';

export async function conectarMcp(token) {
  const cliente = new Client({ name: 'pruebas-ptap', version: '1.0.0' });
  const transporte = new StreamableHTTPClientTransport(new URL(`${API}/mcp`), {
    requestInit: { headers: token ? { Authorization: `Bearer ${token}` } : {} },
  });
  await cliente.connect(transporte);
  return cliente;
}

// Texto de un resultado de herramienta (o el error).
export const textoDe = (r) => r?.content?.map((c) => c.text).join('\n') ?? '';

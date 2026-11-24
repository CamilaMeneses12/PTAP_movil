import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { opcional } from '../config.js';

export interface MensajeModelo {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

// 'auto': nube y, si falla, local. 'nube' o 'local': solo ese.
export const MODOS = ['auto', 'nube', 'local'] as const;
export type Modo = (typeof MODOS)[number];

interface Proveedor {
  nombre: 'nube' | 'local';
  url: string;
  key: string;
  modelo: string;
  esperaMs: number;
}

export interface Conversacion {
  proveedor: 'nube' | 'local';
  modelo: string;
  partes: AsyncGenerator<string>;
}

// Habla con cualquier modelo de formato OpenAI (/chat/completions): Groq en la nube u Ollama local.
@Injectable()
export class IaService {
  private readonly log = new Logger('IA');

  private proveedores(modo: Modo): Proveedor[] {
    const nube: Proveedor = {
      nombre: 'nube',
      url: opcional('NUBE_URL', 'https://api.groq.com/openai/v1'),
      key: opcional('NUBE_KEY'),
      modelo: opcional('NUBE_MODELO', 'openai/gpt-oss-20b'),
      esperaMs: 20_000,
    };
    const local: Proveedor = {
      nombre: 'local',
      url: opcional('LOCAL_URL', 'http://localhost:11434/v1'),
      key: opcional('LOCAL_KEY', 'ollama'),
      modelo: opcional('LOCAL_MODELO', 'llama3.2'),
      // La primera vez Ollama carga el modelo en memoria: puede tardar.
      esperaMs: 120_000,
    };
    const conNube = nube.key ? [nube] : [];
    if (modo === 'nube') return conNube;
    if (modo === 'local') return [local];
    return [...conNube, local];
  }

  // Abre la conversación con el primer proveedor que responda. Si ninguno responde, 503.
  async conversar(mensajes: MensajeModelo[], modo: Modo = 'auto'): Promise<Conversacion> {
    const errores: string[] = [];
    for (const p of this.proveedores(modo)) {
      try {
        const respuesta = await fetch(`${p.url}/chat/completions`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${p.key}` },
          body: JSON.stringify({
            model: p.modelo,
            messages: mensajes,
            stream: true,
            temperature: 0.3,
            ...(p.nombre === 'nube' && opcional('NUBE_RAZONAMIENTO') ? { reasoning_effort: opcional('NUBE_RAZONAMIENTO') } : {}),
          }),
          signal: AbortSignal.timeout(p.esperaMs),
        });
        if (!respuesta.ok || !respuesta.body) {
          throw new Error(`HTTP ${respuesta.status} ${(await respuesta.text()).slice(0, 160)}`);
        }
        return { proveedor: p.nombre, modelo: p.modelo, partes: this.leerFlujo(respuesta.body) };
      } catch (error) {
        const motivo = `${p.nombre} (${p.modelo}): ${(error as Error).message}`;
        this.log.warn(`No respondió ${motivo}`);
        errores.push(motivo);
      }
    }
    throw new ServiceUnavailableException(
      errores.length ? `No hay un modelo disponible. ${errores.join(' | ')}` : 'No hay un modelo configurado para ese modo',
    );
  }

  // Lee la respuesta por partes (Server-Sent Events: "data: {...}").
  private async *leerFlujo(cuerpo: ReadableStream<Uint8Array>): AsyncGenerator<string> {
    const decodificador = new TextDecoder();
    let pendiente = '';
    for await (const trozo of cuerpo as unknown as AsyncIterable<Uint8Array>) {
      pendiente += decodificador.decode(trozo, { stream: true });
      const lineas = pendiente.split('\n');
      pendiente = lineas.pop() ?? '';
      for (const linea of lineas) {
        const datos = linea.trim();
        if (!datos.startsWith('data:')) continue;
        const json = datos.slice(5).trim();
        if (json === '[DONE]') return;
        try {
          const texto = JSON.parse(json)?.choices?.[0]?.delta?.content;
          if (texto) yield texto as string;
        } catch {
          // Línea incompleta o de control: se ignora.
        }
      }
    }
  }
}

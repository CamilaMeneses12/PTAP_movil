import { McpServer } from '@modelcontextprotocol/server';
import { z } from 'zod';
import { TIPOS_REGISTRO } from '../planta/parametro.entity.js';
import { PlantaService } from '../planta/planta.service.js';
import { RegistrosService } from '../registros/registros.service.js';
import { puedeEscribir } from '../usuarios/decoradores.js';
import type { Actor } from '../usuarios/decoradores.js';

const resultado = (datos: unknown) => ({
  content: [{ type: 'text' as const, text: JSON.stringify(datos, null, 2) }],
});

// Un error de negocio se devuelve como resultado, para que el modelo lo lea y corrija.
const fallo = (error: unknown) => ({
  isError: true,
  content: [{ type: 'text' as const, text: (error as Error).message ?? String(error) }],
});

const seguro = async (accion: () => Promise<unknown>) => {
  try {
    return resultado(await accion());
  } catch (error) {
    return fallo(error);
  }
};

// Se crea un servidor por petición y para un usuario concreto: cada rol ve solo sus herramientas.
//   consultor_siga: 3 (solo consulta) · operario: 5 · administrador: 6
export function crearServidorMcp(planta: PlantaService, registros: RegistrosService, actor: Actor): McpServer {
  const escribe = puedeEscribir(actor);
  const servidor = new McpServer(
    { name: 'ptap', version: '1.0.0' },
    {
      instructions:
        'Herramientas del Asistente PTAP (planta de tratamiento de agua potable, datos de práctica). ' +
        `Usuario: ${actor.nombre}, rol ${actor.rol}. ` +
        'Antes de registrar una medición, consulte los parámetros con consultar_parametros ' +
        'y confirme con el usuario los valores.',
    },
  );

  servidor.registerTool(
    'consultar_planta',
    {
      title: 'Consultar información de la planta',
      description: 'Devuelve el nombre, la ubicación, la fuente de agua y la norma de referencia de la planta.',
      annotations: { readOnlyHint: true },
    },
    () => seguro(() => planta.informacion()),
  );

  servidor.registerTool(
    'consultar_parametros',
    {
      title: 'Consultar parámetros y rangos',
      description:
        'Lista los parámetros que se miden en la planta (id, nombre, unidad, tipo de registro) con su ' +
        'rango normativo vigente. Sin texto, devuelve todos.',
      inputSchema: z.object({
        texto: z.string().optional().describe('Parte del nombre; por ejemplo: cloro'),
      }),
      annotations: { readOnlyHint: true },
    },
    ({ texto }) => seguro(() => planta.listarParametros(texto)),
  );

  servidor.registerTool(
    'consultar_registros',
    {
      title: 'Consultar registros',
      description:
        (actor.rol === 'operario' ? 'Consulta los registros del usuario. ' : 'Consulta cualquier registro de la planta. ') +
        'Con un código (por ejemplo R-0001) devuelve ese registro; sin código, los últimos diez.',
      inputSchema: z.object({
        codigo: z.string().optional().describe('Código del registro; por ejemplo: R-0001'),
        solo_fuera_de_rango: z.boolean().optional().describe('true para ver solo los registros con valores fuera de rango'),
      }),
      annotations: { readOnlyHint: true },
    },
    ({ codigo, solo_fuera_de_rango }) =>
      seguro(() =>
        codigo
          ? registros.uno(actor, codigo)
          : registros.listar(actor, { limite: 10, soloFueraDeRango: solo_fuera_de_rango === true }),
      ),
  );

  // El consultor SIGA solo consulta: estas herramientas ni siquiera existen para él.
  if (escribe) {
    servidor.registerTool(
      'registrar_medicion',
      {
        title: 'Registrar una medición',
        description:
          `Registra una medición a nombre de ${actor.nombre} y devuelve su código. ` +
          'Úsela solo cuando el usuario haya confirmado los valores. Los valores fuera de rango se ' +
          'guardan igual, marcados.',
        inputSchema: z.object({
          tipo: z.enum(TIPOS_REGISTRO).describe('fisicoquimico, medidores o caudal'),
          valores: z
            .array(
              z.object({
                parametro: z.string().describe('id del parámetro, según consultar_parametros'),
                valor: z.number().describe('Valor medido'),
              }),
            )
            .min(1)
            .describe('Valores medidos'),
          observacion: z.string().max(300).optional().describe('Observación opcional'),
        }),
        annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: false },
      },
      (datos) => seguro(() => registros.crear(actor, datos, 'mcp')),
    );

    servidor.registerTool(
      'anular_registro',
      {
        title: 'Anular registro',
        description:
          'Anula un registro. No se puede deshacer: úsela solo si el usuario lo pidió de forma explícita y ' +
          'confirmó el código.' +
          (actor.rol === 'operario' ? ' Un operario solo puede anular sus registros pendientes.' : ''),
        inputSchema: z.object({ codigo: z.string().describe('Código del registro; por ejemplo: R-0001') }),
        annotations: { readOnlyHint: false, destructiveHint: true, openWorldHint: false },
      },
      ({ codigo }) => seguro(() => registros.cambiarEstado(actor, codigo, 'anulado')),
    );
  }

  // Solo el administrador revisa y aprueba.
  if (actor.rol === 'administrador') {
    servidor.registerTool(
      'cambiar_estado_registro',
      {
        title: 'Revisar o aprobar un registro',
        description: 'Avanza un registro: pendiente → revisado → aprobado. Úsela cuando el administrador lo indique.',
        inputSchema: z.object({
          codigo: z.string().describe('Código del registro; por ejemplo: R-0001'),
          estado: z.enum(['revisado', 'aprobado']).describe('Nuevo estado'),
        }),
        annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: false },
      },
      ({ codigo, estado }) => seguro(() => registros.cambiarEstado(actor, codigo, estado)),
    );
  }

  return servidor;
}

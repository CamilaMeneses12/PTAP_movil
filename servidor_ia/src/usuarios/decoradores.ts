import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import type { Rol } from './usuario.entity.js';

// Quien hace la petición, tal como lo deja la guardia después de validar el token.
export interface Actor {
  id: string;
  nombre: string;
  correo: string;
  rol: Rol;
}

export const PUBLICO = 'publico';
export const ROLES_PERMITIDOS = 'roles';

// @Publico(): la ruta no exige token.
export const Publico = () => SetMetadata(PUBLICO, true);

// @Roles('administrador'): solo esos roles pueden usar la ruta.
export const Roles = (...roles: Rol[]) => SetMetadata(ROLES_PERMITIDOS, roles);

// @UsuarioActual() actor: Actor, en los parámetros de un controlador.
export const UsuarioActual = createParamDecorator(
  (_dato: unknown, ctx: ExecutionContext): Actor => ctx.switchToHttp().getRequest().usuario,
);

// Quién puede ver todos los registros de la planta (y no solo los suyos).
export const veTodo = (actor: Actor) => actor.rol === 'administrador' || actor.rol === 'consultor_siga';
// Quién puede crear o modificar registros.
export const puedeEscribir = (actor: Actor) => actor.rol === 'operario' || actor.rol === 'administrador';

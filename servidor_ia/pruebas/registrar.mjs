// Uso: node pruebas/registrar.mjs "Nombre Apellido" correo@ptap.test Clave2026xx
import { llamar, mostrar } from './comun.mjs';

const [nombre, correo, clave] = process.argv.slice(2);
if (!clave) {
  console.log('Uso: node pruebas/registrar.mjs "Nombre" correo clave');
  process.exit(1);
}
mostrar(await llamar('POST', '/api/auth/registro', { cuerpo: { nombre, correo, clave } }));

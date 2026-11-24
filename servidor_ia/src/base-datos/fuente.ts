import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { opcionesBaseDatos } from './opciones.js';

// La fuente de datos que usa el comando typeorm para generar y aplicar migraciones.
export default new DataSource(opcionesBaseDatos);

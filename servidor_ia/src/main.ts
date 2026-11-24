import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { networkInterfaces } from 'node:os';
import { AppModule } from './app.module.js';
import { opcional } from './config.js';

const app = await NestFactory.create(AppModule);

// Encabezados de seguridad.
app.use(helmet());
// La app móvil no es un navegador, pero se permite CORS para probar desde /docs y otras páginas.
app.enableCors({ exposedHeaders: ['X-Proveedor', 'X-Modelo'] });

// Validación de toda petición: rechaza campos no declarados (protección contra asignación masiva).
app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));

// Documentación interactiva en /docs.
const documento = SwaggerModule.createDocument(
  app,
  new DocumentBuilder()
    .setTitle('API del Asistente PTAP')
    .setDescription('Usuarios, roles, registros de la planta, chatbot (nube + local) y servidor MCP')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build(),
);
SwaggerModule.setup('docs', app, documento);

const puerto = Number(opcional('PUERTO', '3100'));
// 0.0.0.0: el celular la alcanza por la red Wi-Fi de la planta.
await app.listen(puerto, '0.0.0.0');

const ips = Object.values(networkInterfaces())
  .flat()
  .filter((i) => i && i.family === 'IPv4' && !i.internal)
  .map((i) => `http://${i!.address}:${puerto}`);
console.log(`API del Asistente PTAP en http://localhost:${puerto} (documentación en /docs)`);
if (ips.length) console.log(`Desde el celular (misma red Wi-Fi): ${ips.join('  ')}`);

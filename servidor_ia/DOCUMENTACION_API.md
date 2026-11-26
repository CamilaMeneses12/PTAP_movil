# Documentación de la API del Asistente PTAP

API REST de la Planta de Tratamiento de Agua Potable (PTAP Villa Clara, SENA). Maneja usuarios y roles, los registros de la planta (fisicoquímicos, medidores y caudal) y el chat del asistente con inteligencia artificial.

| Dato | Valor |
|---|---|
| Tecnología | NestJS (Node.js + TypeScript), TypeORM |
| Base de datos | PostgreSQL |
| Dirección base | `http://localhost:3100/api` |
| Documentación interactiva | `http://localhost:3100/docs` (Swagger) |
| Autenticación | Token JWT en el encabezado `Authorization: Bearer <token>` |
| Formato | JSON (excepto la respuesta del chat, que es texto) |

---

## 1. Paso a paso para instalar y correr la API

### Requisitos
- Node.js 20.19 o superior
- PostgreSQL (versión 14 o superior)

### Paso 1. Crear la base de datos
Abra pgAdmin o la consola `psql -U postgres` y ejecute:
```sql
CREATE DATABASE ptap_ia;
```

### Paso 2. Configurar el archivo `.env`
En la carpeta `servidor_ia`, copie `.env.ejemplo` como `.env` y complete:
```
DB_HOST=localhost
DB_PUERTO=5432
DB_NOMBRE=ptap_ia
DB_USUARIO=postgres
DB_CLAVE=<contraseña de postgres>
JWT_SECRETO=<texto aleatorio de 32 caracteres o más>
ADMIN_CORREO=admin@ptap.test
ADMIN_CLAVE=<clave de 10+ caracteres con letras y números>
NUBE_KEY=<clave de Groq, solo necesaria para el chat>
PUERTO=3100
```
El `JWT_SECRETO` se puede generar con:
```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
```

### Paso 3. Instalar dependencias
```powershell
cd servidor_ia
npm install
```

### Paso 4. Crear las tablas (migraciones)
```powershell
npm run migracion:correr
```
Crea las tablas `planta`, `parametros`, `usuarios`, `registros`, `registro_valores` y `mensajes`.

### Paso 5. Cargar los datos iniciales (semilla)
```powershell
npm run semilla
```
Carga la planta, los 13 parámetros con sus rangos normativos y el usuario administrador.

### Paso 6. Arrancar la API
```powershell
npm start
```
Debe aparecer: `API del Asistente PTAP en http://localhost:3100 (documentación en /docs)`.

### Paso 7. Probar en Swagger
1. Abra `http://localhost:3100/docs`.
2. Ejecute `POST /api/auth/entrar` con el correo y la clave del administrador.
3. Copie el `token` de la respuesta.
4. Pulse **Authorize** (arriba a la derecha), pegue el token y confirme.
5. Ya puede probar las rutas protegidas.

---

## 2. Autenticación y roles

1. El usuario inicia sesión con `POST /api/auth/entrar` y recibe un **token JWT**.
2. En cada petición protegida envía el encabezado `Authorization: Bearer <token>`.
3. El token de la app dura **8 horas**; el token para asistentes MCP dura **7 días**.

| Rol | Qué puede hacer |
|---|---|
| `operario` | Crear registros, ver **solo los suyos** y anular uno suyo mientras esté pendiente |
| `administrador` | Ver y modificar todos los registros, ver usuarios y cambiar roles |
| `consultor_siga` | Ver todos los registros (solo lectura) |

Toda cuenta nueva se crea como `operario`. Solo un administrador puede cambiar el rol.

---

## 3. Rutas de la API

Resumen (🔓 pública, 🔒 requiere token, 👑 solo administrador):

| Método | Ruta | Acceso | Para qué sirve |
|---|---|---|---|
| GET | `/api/salud` | 🔓 | Saber si la API y la base de datos están funcionando |
| GET | `/api/planta` | 🔓 | Información de la planta |
| GET | `/api/parametros` | 🔓 | Parámetros de calidad con sus rangos normativos |
| POST | `/api/auth/registro` | 🔓 | Crear una cuenta |
| POST | `/api/auth/entrar` | 🔓 | Iniciar sesión y obtener el token |
| GET | `/api/auth/yo` | 🔒 | Ver el usuario dueño del token |
| POST | `/api/auth/token-mcp` | 🔒 | Obtener token para conectar un asistente de IA (MCP) |
| GET | `/api/usuarios` | 👑 | Listar usuarios |
| PATCH | `/api/usuarios/{id}/rol` | 👑 | Cambiar el rol de un usuario |
| GET | `/api/registros` | 🔒 | Listar registros |
| POST | `/api/registros` | 🔒 | Crear un registro |
| GET | `/api/registros/{codigo}` | 🔒 | Ver un registro |
| PATCH | `/api/registros/{codigo}/estado` | 🔒 | Cambiar el estado de un registro |
| GET | `/api/chat/historial` | 🔒 | Ver la conversación con el asistente |
| POST | `/api/chat` | 🔒 | Enviar un mensaje al asistente |

### 3.1 Salud

#### `GET /api/salud`
Respuesta `200`:
```json
{ "estado": "ok", "base_datos": "ok" }
```
Si PostgreSQL no responde, `base_datos` vale `"sin conexión"`.

### 3.2 Planta

#### `GET /api/planta`
Respuesta `200`:
```json
{
  "id": 1,
  "nombre": "PTAP Villa Clara",
  "ubicacion": "SENA, Centro de Gestión Agroempresarial",
  "fuenteAgua": "Quebrada La Seca",
  "normaReferencia": "Resolución 2115 de 2007 y formato DO-F-070"
}
```

#### `GET /api/parametros?buscar=ph`
`buscar` es opcional y filtra por nombre. Respuesta `200` (fragmento):
```json
[
  {
    "id": "ph_tratada",
    "nombre": "pH agua tratada",
    "unidad": "pH",
    "tipo": "fisicoquimico",
    "minimo": 6.5,
    "maximo": 9,
    "activo": true,
    "rango": "6,5–9 pH"
  }
]
```

Parámetros disponibles:

| Tipo | Identificadores |
|---|---|
| `fisicoquimico` | `cloro_residual`, `color_aparente`, `color_cruda`, `ph_cruda`, `ph_tratada`, `turbidez_cruda`, `turbidez_tratada` |
| `medidores` | `agua_no_registrada`, `consumo_macromedidor`, `consumo_micromedidores` |
| `caudal` | `caudal_entrada`, `caudal_quebrada`, `caudal_salida` |

### 3.3 Usuarios y autenticación

#### `POST /api/auth/registro`
Cuerpo:
```json
{ "nombre": "Andrea Ríos", "correo": "andrea@ptap.test", "clave": "AguaClara2026" }
```
Reglas: nombre de 2 a 100 caracteres, correo válido, clave de 10 a 72 caracteres con al menos una letra y un número.
Errores: `400` datos inválidos, `409` el correo ya existe.

#### `POST /api/auth/entrar`
Cuerpo:
```json
{ "correo": "admin@ptap.test", "clave": "<ADMIN_CLAVE del archivo .env>" }
```
Respuesta `200`:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "usuario": {
    "id": "c1520e50-f49d-429f-900f-69367e3aff53",
    "nombre": "Administrador",
    "correo": "admin@ptap.test",
    "rol": "administrador"
  }
}
```
Errores: `401` correo o clave incorrectos, `429` más de 10 intentos por minuto.

#### `GET /api/auth/yo` 🔒
Devuelve el usuario del token:
```json
{ "id": "c1520e50-...", "nombre": "Administrador", "correo": "admin@ptap.test", "rol": "administrador" }
```

#### `POST /api/auth/token-mcp` 🔒
Devuelve un token de 7 días para conectar un asistente de IA por el protocolo MCP:
```json
{ "token": "eyJ...", "vigencia": "7 días", "rol": "administrador" }
```

#### `GET /api/usuarios` 👑
Lista todos los usuarios. Si quien consulta no es administrador: `403`.

#### `PATCH /api/usuarios/{id}/rol` 👑
Cuerpo:
```json
{ "rol": "consultor_siga" }
```
`rol` debe ser `operario`, `administrador` o `consultor_siga`. Errores: `400` rol inválido o id que no es UUID, `404` usuario no existe.

### 3.4 Registros de la planta

Cada registro recibe un código `R-0001`, `R-0002`, etc. El responsable **sale del token**: nadie puede registrar a nombre de otro. La API compara cada valor con su rango normativo y marca `fuera_de_rango`.

#### `POST /api/registros` 🔒
Cuerpo:
```json
{
  "tipo": "fisicoquimico",
  "valores": [
    { "parametro": "ph_tratada", "valor": 7.2 },
    { "parametro": "cloro_residual", "valor": 2.5 }
  ],
  "observacion": "Muestra tomada en el tanque de almacenamiento"
}
```
Reglas: `tipo` es `fisicoquimico`, `medidores` o `caudal`; entre 1 y 30 valores; cada parámetro debe pertenecer al tipo; observación de máximo 300 caracteres.

Respuesta `201`:
```json
{
  "codigo": "R-0001",
  "fecha": "2026-11-24T21:04:20.926Z",
  "tipo": "fisicoquimico",
  "origen": "api",
  "responsable": "Administrador",
  "valores": [
    { "parametro": "ph_tratada", "nombre": "pH agua tratada", "valor": 7.2, "unidad": "pH", "rango": "6,5–9 pH", "fuera_de_rango": false },
    { "parametro": "cloro_residual", "nombre": "Cloro residual libre", "valor": 2.5, "unidad": "mg/L", "rango": "0,3–2 mg/L", "fuera_de_rango": true }
  ],
  "observacion": "Muestra tomada en el tanque de almacenamiento",
  "fuera_de_rango": true,
  "estado": "pendiente"
}
```
Errores: `400` datos inválidos, `403` el consultor SIGA no puede registrar.

#### `GET /api/registros?fuera_de_rango=true` 🔒
Lista los últimos 20 registros, del más reciente al más antiguo. Con `fuera_de_rango=true` muestra solo los que tienen algún valor fuera de norma. El operario solo ve los suyos.

#### `GET /api/registros/{codigo}` 🔒
Ejemplo: `GET /api/registros/R-0001`. Error `404` si no existe o si es de otro operario.

#### `PATCH /api/registros/{codigo}/estado` 🔒
Cuerpo:
```json
{ "estado": "revisado" }
```
Cambios de estado permitidos:

```
pendiente ──► revisado ──► aprobado
    │             │
    └──► anulado ◄┘
```
- `aprobado` y `anulado` son finales.
- El operario solo puede pasar **su** registro de `pendiente` a `anulado`.
- El consultor SIGA no puede cambiar estados (`403`).

### 3.5 Chat del asistente

#### `POST /api/chat` 🔒
Cuerpo:
```json
{ "mensaje": "¿Cuál es el rango del cloro residual?", "modo": "auto", "sesion": "app" }
```
- `mensaje`: obligatorio, máximo 500 caracteres.
- `modo`: `auto` (nube y, si falla, modelo local), `nube` o `local`. Por defecto `auto`.
- `sesion`: nombre de la conversación, por defecto `app`.

La respuesta es **texto plano enviado por partes** (la app lo muestra mientras se genera). Los encabezados `X-Proveedor` y `X-Modelo` dicen qué modelo respondió. Error `503` si ningún modelo está disponible.

#### `GET /api/chat/historial?sesion=app` 🔒
Devuelve los mensajes anteriores de esa conversación del usuario.

---

## 4. Códigos de respuesta

| Código | Significado |
|---|---|
| `200` / `201` | Correcto / creado |
| `400` | Datos inválidos (el mensaje explica qué campo falla) |
| `401` | Falta el token, es inválido o venció |
| `403` | El rol no tiene permiso |
| `404` | No existe (o no le pertenece al operario) |
| `409` | El correo ya está registrado |
| `429` | Demasiadas peticiones (120 por minuto; 10 por minuto al iniciar sesión) |
| `503` | El chat no tiene modelo de IA disponible |

Ejemplo de error:
```json
{ "message": "Falta el token de acceso", "error": "Unauthorized", "statusCode": 401 }
```

---

## 5. Seguridad

- Contraseñas guardadas con scrypt y una sal distinta por usuario (nunca en texto plano).
- Tokens JWT firmados con `JWT_SECRETO`, con vencimiento.
- Se rechazan campos no declarados en el cuerpo (evita que alguien se asigne un rol).
- Límite de peticiones para frenar ataques de fuerza bruta.
- Encabezados de seguridad HTTP con Helmet.
- El archivo `.env` no se sube al repositorio.

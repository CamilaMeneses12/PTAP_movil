# Sistema Móvil PTAP - Planta de Tratamiento de Agua Potable SENA La Salada

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Plataforma](https://img.shields.io/badge/Plataforma-Android%20Solo-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Base de Datos](https://img.shields.io/badge/Supabase-PostgreSQL%20%2B%20RLS-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Estado](https://img.shields.io/badge/Pruebas-42%2F42%20Aprobadas-brightgreen)](#pruebas-automatizadas)

Aplicación móvil desarrollada exclusivamente para **Android** como proyecto de investigación aplicada del **SENA - Centro de los Recursos Naturales Renovables La Salada (Regional Antioquia)**. 

La solución digitaliza y reemplaza los formatos manuales físicos y en hojas de cálculo Excel utilizados diariamente por los operarios de la planta de tratamiento de agua potable (PTAP):
1. **Formato DO-F-070**: *Registro Diario de Análisis Fisicoquímico del Agua en Planta de Tratamiento* (Sistema Integrado de Gestión y Autocontrol - SIGA).
2. **Formato Medidores de Agua**: *Balance Hídrico y Control de Agua No Registrada / Pérdidas*.
3. **Formato Quebrada La Seca (V4)**: *Tabla para Cálculo de Caudal mediante el Método del Flotador*.

---

## 📋 Características Principales

- **Diseño Ergonómico de Campo**: Interfaz en Material 3 optimizada para uso con una sola mano bajo luz solar directa (botones táctiles de alto contraste, teclados numéricos automáticos y tarjetas claras).
- **Control de Calidad Normativo (Res. 2115 de 2007)**:
  - Validación en vivo de pH (6.5 – 9.0), Cloro Residual Libre (0.3 – 2.0 mg/L), Turbidez (≤ 2.0 UNT) y Color (≤ 15 UPC).
  - Alerta visual inmediata en caso de parámetro fuera de norma, requiriendo registro mandatorio de observación técnica antes de guardar.
- **Balance Hídrico de Micromedidores y Macromedidor**:
  - Registro de los 8 micromedidores oficiales de la sede: `ENCC`, `SENNOVA`, `LABORATORIOS`, `BIOCABAÑA`, `CAFETERIA`, `PECUARIA`, `AGROINDUSTRIA` y `GASTRONOMIA`.
  - Precarga automática de lecturas anteriores para evitar errores humanos de digitación.
  - Cálculo en tiempo real de consumo total de micros, consumo de macromedidor, volumen de agua no registrada ($m^3$) y porcentaje de pérdidas.
- **Aforo Hidráulico de Caudal (Quebrada La Seca)**:
  - Implementación exacta del método del flotador con factor de corrección de velocidad ($K = 0.80 - 0.85$).
  - Cálculo simultáneo en $m^3/s$, $m^3/h$, $L/s$ y $L/h$.
  - Tablero analítico interactivo con gráficas temporales mediante `fl_chart`, filtros mensuales y línea promedio histórica.
- **Historial Unificado y Filtros Avanzados**:
  - Consulta integral con filtros combinables por módulo, rango de fechas, operario responsable y conmutador de *Solo Alertas*.
  - Búsqueda textual instantánea.
- **Exportación Oficial (PDF y Excel) y Compartición**:
  - Generación de documentos PDF oficiales apaisados con membrete institucional SENA y notas técnicas.
  - Exportación en hojas de cálculo Excel (`.xlsx`) fieles a las columnas, unidades y fórmulas de los formatos originales.
  - Integración nativa con `SharePlus` para compartir reportes directamente por WhatsApp, Gmail o guardado en el almacenamiento local.
- **Seguridad y Control de Acceso por Roles (RBAC)**:
  - Perfiles tipificados: **Operario** (captura y edición), **Administrador** (gestión total y catálogos) y **Consultor SIGA** (auditoría y exportación en modo solo lectura).
  - Políticas de seguridad a nivel de filas (**Row Level Security - RLS**) en PostgreSQL/Supabase.

---

## 🏗️ Arquitectura del Software

El proyecto sigue los principios de **Clean Architecture** (Arquitectura Limpia) con separación estricta de responsabilidades:

```text
app_movil/
├── formatos/                         # FUENTE DE VERDAD (Excel originales intactos)
│   ├── Formato Calidad de Agua 2026 - V1.xlsx
│   └── Tabla de Calculo Caudal Quebrada la seca - V4 (1).xlsx
├── lib/
│   ├── core/                         # Núcleo de la aplicación
│   │   ├── constants/                # Colores institucionales, cadenas, temas
│   │   ├── routes/                   # Enrutamiento declarativo con GoRouter
│   │   ├── theme/                    # Tema Material 3 de alto contraste
│   │   └── utils/                    # Configuración central de Supabase
│   ├── data/                         # Capa de datos y persistencia
│   │   ├── models/                   # Modelos de dominio serializables
│   │   ├── repositories/             # Repositorios con soporte online / offline
│   │   └── services/                 # Servicios de exportación PDF, Excel y Share
│   ├── domain/                       # Lógica de negocio y fórmulas matemáticas puras
│   │   ├── calculos_caudal.dart      # Fórmulas del flotador
│   │   ├── calculos_medidores.dart   # Balance hídrico y pérdidas
│   │   └── validador_rangos.dart     # Reglas Resolución 2115 de 2007
│   ├── presentation/                 # Capa de interfaz de usuario (UI)
│   │   ├── admin/                    # Gestión de usuarios, medidores y rangos
│   │   ├── auth/                     # Inicio de sesión, perfiles y roles
│   │   ├── flow/                     # Caudal de la quebrada La Seca y gráficas
│   │   ├── history/                  # Historial unificado y filtros
│   │   ├── home/                     # Menú principal reactivo por rol
│   │   ├── meters/                   # Lectura de medidores y balance
│   │   ├── physicochemical/          # Formulario y detalle DO-F-070
│   │   └── reports/                  # Centro de exportación PDF / Excel
│   └── main.dart                     # Punto de entrada de la aplicación
├── supabase/
│   └── schema.sql                    # Script DDL completo de PostgreSQL + RLS + Triggers
└── test/                             # 42 pruebas unitarias automatizadas
```

---

## 🗄️ Configuración de la Base de Datos (Supabase)

1. Crea un proyecto en [Supabase](https://supabase.com).
2. Ve al **SQL Editor** del panel de Supabase y ejecuta el contenido completo del archivo:
   [`supabase/schema.sql`](file:///C:/Users/SENA/Documents/3312744/Diego%20Calderon/app_movil/supabase/schema.sql)
   - Esto creará las tablas: `perfiles`, `medidores_catalogo`, `parametros_catalogo`, `puntos_muestreo_red`, `registros_fisicoquimicos`, `mediciones_red`, `jornadas_medidores`, `lecturas_medidores` y `aforos_caudal`.
   - Habilita automáticamente RLS, triggers de sincronización con `auth.users` y datos semilla iniciales.
3. Copia el archivo `.env.example` como `.env` en la raíz del proyecto y añade tus credenciales:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-anon-key-aqui
   ```
   *(Nota: si no se configuran variables de Supabase, la app cuenta con un mecanismo de respaldo local automático para permitir pruebas de campo sin conexión).*

---

## 🚀 Instalación y Ejecución

### Prerrequisitos
- Flutter SDK 3.47+ o superior.
- Android SDK instalado con CMake y NDK configurados.
- Dispositivo Android físico o emulador con API 26+ (Android 8.0 o superior).

### Pasos
```powershell
# 1. Obtener dependencias
flutter pub get

# 2. Verificar análisis estático (0 errores)
flutter analyze

# 3. Ejecutar suite de pruebas unitarias
flutter test

# 4. Iniciar la aplicación en el dispositivo Android conectado
flutter run -d <id-dispositivo>
```

---

## 🧪 Pruebas Automatizadas

El proyecto incluye **42 pruebas unitarias** que certifican las fórmulas matemáticas, validaciones normativas, repositorios y exportaciones:

```powershell
flutter test
```

| Archivo de Prueba | Cobertura / Módulo Verificado |
|---|---|
| `test/domain_test.dart` | Fórmulas del flotador, balance de pérdidas y límites de Res. 2115 |
| `test/auth_test.dart` | Permisos de roles (Operario, Admin, Consultor SIGA) y sesiones |
| `test/fisicoquimico_test.dart` | Captura DO-F-070, 5 puntos de red y validación de rangos |
| `test/medidores_test.dart` | Los 9 medidores, lectura anterior/actual y balance con datos del Excel |
| `test/caudal_test.dart` | Histórico mensual Feb 2025 - Oct 2026 y preparación para `fl_chart` |
| `test/historial_test.dart` | Unificación cronológica, filtros por fecha, tipo, usuario y alertas |
| `test/export_test.dart` | Firmas binarias válidas de documentos PDF (`%PDF`) y libros Excel (`PK`) |
| `test/admin_test.dart` | Cambio dinámico de roles, activación de medidores y calibración de rangos |

---

## 📦 Generación del APK de Producción

Para compilar el paquete instalable para dispositivos Android:

```powershell
# Compilar APK universal listo para instalar en campo
flutter build apk --release
```

El instalador final se generará en la ruta:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 👥 Roles de Usuario y Credenciales de Prueba

En modo de prueba o desarrollo, la aplicación permite ingresar con cuentas demo preconfiguradas:

- **Operario PTAP** (`operario@sena.edu.co` / `operario123`):
  - Habilitado para crear y editar mediciones de calidad, lecturas de medidores y aforos de caudal.
- **Administrador** (`admin@sena.edu.co` / `admin123`):
  - Acceso total a todas las funciones operativas, más el módulo de Administración para gestionar usuarios, catálogo de medidores y calibración de rangos normativos.
- **Consultor SIGA** (`siga@sena.edu.co` / `siga123`):
  - Modo auditoría con acceso a consultas históricas, tableros analíticos y exportación a PDF y Excel (botones de edición ocultos o deshabilitados).

---
*Centro de los Recursos Naturales Renovables La Salada — SENA Regional Antioquia*

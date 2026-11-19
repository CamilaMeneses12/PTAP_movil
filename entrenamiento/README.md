# Entrenamiento del lector de micromedidores (IA local)

Modelo propio que lee los 8 rodillos del contador (4 blancos = m³, 4 rojos = decimales, ej. `0813,6267`).
Se entrena en este PC (sin GPU) y funciona **dentro del celular sin internet** (TensorFlow Lite).
En la app, la cámara usa primero este modelo y lo compara con ML Kit; gana la lectura más creíble
frente a la lectura anterior.

## Primera vez: preparar el entorno

```powershell
cd entrenamiento
py -3.12 -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
```

## Entrenar

```powershell
# 1. Recortar la ventanita de las fotos reales (fotos_reales/ + etiquetas_reales.csv)
.venv\Scripts\python recortar_reales.py        # revise datos\reales_revision.png

# 2. Generar imágenes sintéticas del contador (≈ 3–5 min)
.venv\Scripts\python generar_sinteticos.py --cantidad 60000

# 3. Entrenar y exportar a la app (≈ 20–60 min en CPU)
.venv\Scripts\python entrenar.py                # solo sintéticas: el examen con fotos reales es honesto
.venv\Scripts\python entrenar.py --con-reales   # + fotos reales (cuando haya bastantes)

# 4. Medir con las fotos reales
.venv\Scripts\python evaluar.py
```

`entrenar.py` copia el modelo a `../assets/modelos/lector_medidor.tflite`. Después ejecute la app
(`flutter run`) para que el celular use el modelo nuevo.

## Seguir mejorando con fotos de campo

Cada vez que el operario confirma una lectura con la cámara, la app guarda el recorte y el número
correcto en el celular. Para traerlos y volver a entrenar:

```powershell
.venv\Scripts\python descargar_dataset_celular.py   # celular conectado por USB
.venv\Scripts\python entrenar.py --con-reales
.venv\Scripts\python evaluar.py
```

Con **300 o más** lecturas reales de varios medidores el modelo debería superar claramente a ML Kit.
Separe algunas fotos (no las use para entrenar) si quiere un examen honesto.

## Agregar fotos sueltas a mano

1. Copie la foto a `fotos_reales/`.
2. Agregue una fila en `etiquetas_reales.csv`: lectura de 8 dígitos, caja de la ventanita
   (fracciones 0–1 del ancho/alto) y rotación (0, 90 o -90) para dejar los enteros a la izquierda.
3. Ejecute `recortar_reales.py` y revise `datos\reales_revision.png`.

## Archivos

| Archivo | Para qué |
|---|---|
| `comun.py` | Tamaño de entrada (192 × 48, gris) y dígitos. Debe coincidir con `lib/data/services/lector_medidor_ia_service.dart` |
| `generar_sinteticos.py` | Dibuja contadores falsos parecidos al real (rodillos a medio girar, número de serie, reflejos) |
| `recortar_reales.py` | Recorta las fotos reales según `etiquetas_reales.csv` |
| `entrenar.py` | Red neuronal pequeña (8 salidas, una por rodillo) + exportación a TFLite |
| `evaluar.py` | Examen con las fotos reales: % de dígitos y de lecturas completas correctas |
| `descargar_dataset_celular.py` | Trae del celular las lecturas confirmadas (adb) |

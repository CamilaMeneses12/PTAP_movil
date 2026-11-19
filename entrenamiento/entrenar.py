"""Entrena el lector de micromedidores y lo exporta a TensorFlow Lite para la app.

El modelo recibe el recorte del contador (gris, 192 x 48) y devuelve, para cada uno de los
8 rodillos, la probabilidad de cada dígito 0-9  ->  salida [1, 8, 10].

Uso:
  .venv\\Scripts\\python entrenar.py                 # solo imágenes sintéticas
  .venv\\Scripts\\python entrenar.py --con-reales    # + fotos reales de datos/reales (afinado)
Salida:
  modelos/lector_medidor.keras
  modelos/lector_medidor.tflite        (también se copia a ../assets/modelos/)
"""
import argparse
import shutil

import numpy as np
import tensorflow as tf

from comun import ALTO, ANCHO, CARPETA, DATOS, DIGITOS, MODELOS
from evaluar import cargar_reales, evaluar_predicciones


def construir_modelo():
    entrada = tf.keras.Input(shape=(ALTO, ANCHO, 1), name="recorte")
    x = entrada

    def bloque(x, filtros, pool):
        x = tf.keras.layers.Conv2D(filtros, 3, padding="same", use_bias=False)(x)
        x = tf.keras.layers.BatchNormalization()(x)
        x = tf.keras.layers.ReLU()(x)
        x = tf.keras.layers.Conv2D(filtros, 3, padding="same", use_bias=False)(x)
        x = tf.keras.layers.BatchNormalization()(x)
        x = tf.keras.layers.ReLU()(x)
        if pool:
            x = tf.keras.layers.MaxPooling2D(pool)(x)
        return x

    x = bloque(x, 32, (2, 2))    # 24 x 96
    x = bloque(x, 64, (2, 2))    # 12 x 48
    x = bloque(x, 96, (2, 2))    # 6 x 24
    x = bloque(x, 128, (2, 1))   # 3 x 24  (se conserva el ancho: una columna por "trozo" de rodillo)
    x = tf.keras.layers.Flatten()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(256, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(DIGITOS * 10)(x)
    x = tf.keras.layers.Reshape((DIGITOS, 10))(x)
    salida = tf.keras.layers.Softmax(axis=-1, name="digitos")(x)
    return tf.keras.Model(entrada, salida, name="lector_micromedidor")


def aumentar(imagen, etiqueta):
    """Variaciones extra en cada época (las sintéticas ya traen ruido, blur, etc.)."""
    imagen = tf.image.random_brightness(imagen, 0.15)
    imagen = tf.image.random_contrast(imagen, 0.7, 1.3)
    # Pequeño desplazamiento del recorte (el operario nunca encuadra exactamente igual)
    imagen = tf.image.resize_with_crop_or_pad(imagen, ALTO + 6, ANCHO + 12)
    imagen = tf.image.random_crop(imagen, (ALTO, ANCHO, 1))
    return tf.clip_by_value(imagen, 0.0, 1.0), etiqueta


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epocas", type=int, default=20)
    parser.add_argument("--lote", type=int, default=128)
    parser.add_argument("--con-reales", action="store_true",
                        help="Añade al entrenamiento las fotos reales de datos/reales (repetidas)")
    parser.add_argument("--repetir-reales", type=int, default=150)
    args = parser.parse_args()

    datos = np.load(DATOS / "sinteticos.npz")
    X = datos["X"].astype(np.float32)[..., None] / 255.0
    y = datos["y"].astype(np.int32)
    print(f"Sintéticas: {len(X)}")

    reales_X, reales_y, nombres = cargar_reales()
    if args.con_reales and len(reales_X):
        X = np.concatenate([X, np.repeat(reales_X, args.repetir_reales, axis=0)])
        y = np.concatenate([y, np.repeat(reales_y, args.repetir_reales, axis=0)])
        print(f"+ {len(reales_X)} fotos reales x {args.repetir_reales}")

    indices = np.random.default_rng(1).permutation(len(X))
    X, y = X[indices], y[indices]
    corte = int(len(X) * 0.95)
    entrenamiento = (tf.data.Dataset.from_tensor_slices((X[:corte], y[:corte]))
                     .shuffle(8192).map(aumentar, num_parallel_calls=tf.data.AUTOTUNE)
                     .batch(args.lote).prefetch(tf.data.AUTOTUNE))
    validacion = tf.data.Dataset.from_tensor_slices((X[corte:], y[corte:])).batch(args.lote)

    modelo = construir_modelo()
    modelo.summary(print_fn=lambda t: print(t) if "Total params" in t else None)
    modelo.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=[tf.keras.metrics.SparseCategoricalAccuracy(name="acierto_digito")],
    )
    MODELOS.mkdir(exist_ok=True)
    modelo.fit(
        entrenamiento,
        validation_data=validacion,
        epochs=args.epocas,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor="val_loss", patience=4, restore_best_weights=True),
            tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2),
        ],
        verbose=2,
    )
    modelo.save(MODELOS / "lector_medidor.keras")

    if len(reales_X):
        print("\n=== Examen con las fotos REALES (datos/reales) ===")
        if args.con_reales:
            print("(Ojo: estas fotos se usaron para entrenar; el resultado es optimista.)")
        evaluar_predicciones(modelo.predict(reales_X, verbose=0), reales_y, nombres)

    # Exportar a TensorFlow Lite (float16: la mitad de tamaño, misma precisión práctica)
    conversor = tf.lite.TFLiteConverter.from_keras_model(modelo)
    conversor.optimizations = [tf.lite.Optimize.DEFAULT]
    conversor.target_spec.supported_types = [tf.float16]
    tflite = conversor.convert()
    ruta = MODELOS / "lector_medidor.tflite"
    ruta.write_bytes(tflite)
    destino = CARPETA.parent / "assets" / "modelos"
    destino.mkdir(parents=True, exist_ok=True)
    shutil.copy(ruta, destino / "lector_medidor.tflite")
    print(f"\nModelo TFLite: {ruta} ({len(tflite) / 1024:.0f} KB), copiado a {destino}")


if __name__ == "__main__":
    main()

"""Mide qué tan bien lee el modelo las fotos REALES (el examen de verdad).

Uso:
  .venv\\Scripts\\python evaluar.py                      # usa modelos/lector_medidor.tflite
  .venv\\Scripts\\python evaluar.py --keras              # usa modelos/lector_medidor.keras
"""
import argparse

import numpy as np
from PIL import Image

from comun import DATOS, DIGITOS, MODELOS, lectura_a_texto, preprocesar


def cargar_reales():
    """Recortes de datos/reales/*.png con su lectura confirmada (etiquetas_reales.csv + dataset del celular)."""
    carpeta = DATOS / "reales"
    X, y, nombres = [], [], []
    if not carpeta.exists():
        return np.zeros((0,)), np.zeros((0,)), []
    for archivo in sorted(carpeta.glob("*.png")):
        # Nombre: <lectura de 8 dígitos>__<origen>.png
        lectura = archivo.stem.split("__")[0]
        if len(lectura) != DIGITOS or not lectura.isdigit():
            continue
        X.append(preprocesar(Image.open(archivo)))
        y.append([int(c) for c in lectura])
        nombres.append(archivo.name)
    if not X:
        return np.zeros((0,)), np.zeros((0,)), []
    return np.stack(X), np.array(y, dtype=np.int32), nombres


def evaluar_predicciones(probabilidades, y, nombres):
    pred = probabilidades.argmax(-1)
    confianza = probabilidades.max(-1).min(-1)
    aciertos_digito = (pred == y).mean()
    lectura_exacta = (pred == y).all(-1).mean()
    enteros_ok = (pred[:, :4] == y[:, :4]).all(-1).mean()
    for nombre, p, real, c in zip(nombres, pred, y, confianza):
        ok = "OK " if (p == real).all() else "MAL"
        print(f"  {ok}  real {lectura_a_texto(real)}  modelo {lectura_a_texto(p)}  confianza {c:.2f}  {nombre}")
    print(f"\n  Dígitos correctos:        {aciertos_digito * 100:5.1f} %")
    print(f"  Parte entera correcta:    {enteros_ok * 100:5.1f} %")
    print(f"  Lectura completa exacta:  {lectura_exacta * 100:5.1f} %   ({len(y)} fotos)")
    return lectura_exacta


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keras", action="store_true")
    args = parser.parse_args()
    X, y, nombres = cargar_reales()
    if not len(X):
        raise SystemExit("No hay fotos en datos/reales. Ejecute primero recortar_reales.py")

    if args.keras:
        import tensorflow as tf
        modelo = tf.keras.models.load_model(MODELOS / "lector_medidor.keras")
        probabilidades = modelo.predict(X, verbose=0)
    else:
        import tensorflow as tf
        interprete = tf.lite.Interpreter(model_path=str(MODELOS / "lector_medidor.tflite"))
        interprete.allocate_tensors()
        entrada = interprete.get_input_details()[0]
        salida = interprete.get_output_details()[0]
        probabilidades = []
        for x in X:
            interprete.set_tensor(entrada["index"], x[None].astype(np.float32))
            interprete.invoke()
            probabilidades.append(interprete.get_tensor(salida["index"])[0])
        probabilidades = np.array(probabilidades)
    evaluar_predicciones(probabilidades, y, nombres)


if __name__ == "__main__":
    main()

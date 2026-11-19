"""Constantes y preprocesado compartidos por todos los scripts.

IMPORTANTE: la app (lib/data/services/lector_medidor_ia_service.dart) aplica EXACTAMENTE
el mismo preprocesado. Si cambias ALTO, ANCHO o la normalización aquí, cámbialos también allá.
"""
from pathlib import Path

import numpy as np
from PIL import Image

CARPETA = Path(__file__).resolve().parent
DATOS = CARPETA / "datos"
MODELOS = CARPETA / "modelos"

# Entrada del modelo: recorte del contador en escala de grises, 192 x 48 píxeles
ALTO = 48
ANCHO = 192

# Micromedidor instalado: 4 rodillos blancos (m³ enteros) + 4 rojos (decimales) -> 0813,6267
DIGITOS_ENTEROS = 4
DIGITOS_DECIMALES = 4
DIGITOS = DIGITOS_ENTEROS + DIGITOS_DECIMALES


def preprocesar(imagen: Image.Image) -> np.ndarray:
    """Imagen PIL (cualquier tamaño/modo) -> arreglo float32 (ALTO, ANCHO, 1) en [0, 1]."""
    gris = imagen.convert("L").resize((ANCHO, ALTO), Image.BILINEAR)
    return (np.asarray(gris, dtype=np.float32) / 255.0)[..., None]


def lectura_a_texto(digitos) -> str:
    """[0,8,1,3,6,2,6,7] -> '0813,6267'"""
    s = "".join(str(int(d)) for d in digitos)
    return f"{s[:DIGITOS_ENTEROS]},{s[DIGITOS_ENTEROS:]}"

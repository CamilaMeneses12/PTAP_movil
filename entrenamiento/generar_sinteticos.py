"""Genera imágenes sintéticas del contador del micromedidor para entrenar el modelo.

Imita el medidor de las fotos reales (fotos_reales/):
  - ventana ovalada con 8 rodillos: 4 blancos con números negros (m³) y 4 rojos con números blancos
  - rodillos a medio girar (con el arrastre real de un odómetro: 0813,6299 -> 0813,6300)
  - carcasa azul y el número de serie dorado grabado encima ("23 093377m³"), que el modelo debe ignorar
  - inclinación, desenfoque, reflejos, suciedad, ruido y compresión JPEG

Uso:
  .venv\\Scripts\\python generar_sinteticos.py --cantidad 60000
Salida: datos/sinteticos.npz  (X: uint8 [N, 48, 192], y: uint8 [N, 8])
"""
import argparse
import math
import os
import random
from io import BytesIO
from multiprocessing import Pool
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

from comun import ALTO, ANCHO, DATOS, DIGITOS, DIGITOS_ENTEROS

FUENTES_WINDOWS = [
    "arialbd.ttf", "arial.ttf", "ARIALN.TTF", "ARIALNB.TTF", "calibrib.ttf", "calibri.ttf",
    "tahomabd.ttf", "tahoma.ttf", "verdanab.ttf", "segoeuib.ttf", "segoeui.ttf", "bahnschrift.ttf",
    "consolab.ttf", "trebucbd.ttf",
]


def cargar_fuentes():
    rutas = []
    for nombre in FUENTES_WINDOWS:
        ruta = Path("C:/Windows/Fonts") / nombre
        if ruta.exists():
            rutas.append(str(ruta))
    if not rutas:
        raise SystemExit("No se encontraron fuentes en C:/Windows/Fonts")
    return rutas


def valor_a_rodillos(valor: float):
    """Valor continuo (ej. 813.62674) -> [(dígito, fracción de giro)] por rodillo, con arrastre."""
    escala = 10 ** (DIGITOS - DIGITOS_ENTEROS)
    continuo = valor * escala  # 8136267.4 -> último rodillo en 7, a 40 % de girar al 8
    rodillos = []
    fraccion_inferior = continuo - math.floor(continuo)
    entero = int(math.floor(continuo))
    for posicion in range(DIGITOS):  # de derecha (último decimal) a izquierda
        digito = (entero // 10 ** posicion) % 10
        if posicion == 0:
            fraccion = fraccion_inferior
        else:
            # Un rodillo solo gira mientras todos los de su derecha pasan de 9 a 0
            todos_nueve = all((entero // 10 ** p) % 10 == 9 for p in range(posicion))
            fraccion = fraccion_inferior if todos_nueve else 0.0
        rodillos.append((digito, fraccion))
    return list(reversed(rodillos))


def etiqueta(rodillos):
    """El dígito que más se ve en cada rodillo (a partir de la mitad del giro, el siguiente)."""
    return [(d + (1 if f >= 0.5 else 0)) % 10 for d, f in rodillos]


def dibujar_rodillo(ancho, alto, digito, fraccion, fondo, tinta, fuente):
    """Un rodillo con el dígito actual subiendo y el siguiente apareciendo por abajo."""
    celda = Image.new("RGB", (ancho, alto), fondo)
    d = ImageDraw.Draw(celda)
    paso = alto * random.uniform(0.95, 1.15)  # distancia entre números en la cinta
    desplazamiento = fraccion * paso
    for k, valor in ((-1, (digito - 1) % 10), (0, digito), (1, (digito + 1) % 10)):
        y = alto / 2 + k * paso - desplazamiento
        caja = d.textbbox((0, 0), str(valor), font=fuente)
        w, h = caja[2] - caja[0], caja[3] - caja[1]
        d.text((ancho / 2 - w / 2 - caja[0], y - h / 2 - caja[1]), str(valor), fill=tinta, font=fuente)
    # Sombra de curvatura del rodillo (más oscuro arriba y abajo)
    sombra = Image.new("L", (1, alto))
    for y in range(alto):
        t = abs(y - alto / 2) / (alto / 2)
        sombra.putpixel((0, y), int(255 * (1 - 0.45 * t ** 2)))
    sombra = sombra.resize((ancho, alto))
    negro = Image.new("RGB", (ancho, alto), (0, 0, 0))
    return Image.composite(celda, negro, sombra)


def color_aleatorio(base, variacion):
    return tuple(int(np.clip(c + random.uniform(-variacion, variacion), 0, 255)) for c in base)


def generar_muestra(fuentes):
    # Lectura aleatoria; a veces cerca de valores reales de la planta
    if random.random() < 0.3:
        valor = random.uniform(800, 830)
    else:
        valor = random.uniform(0, 9999.9999)
    rodillos = valor_a_rodillos(valor)
    if random.random() < 0.35:  # muchas fotos tienen el último rodillo a medio girar
        d, _ = rodillos[-1]
        rodillos[-1] = (d, random.uniform(0.15, 0.85))

    lienzo_w, lienzo_h = 760, 260
    carcasa = color_aleatorio((25, 70, 205), 35)
    imagen = Image.new("RGB", (lienzo_w, lienzo_h), carcasa)
    d = ImageDraw.Draw(imagen)

    # Textura/brillo de la carcasa plástica
    for _ in range(random.randint(2, 6)):
        x, y = random.randint(0, lienzo_w), random.randint(0, lienzo_h)
        r = random.randint(40, 200)
        d.ellipse((x - r, y - r // 3, x + r, y + r // 3), fill=color_aleatorio(carcasa, 25))

    # Ventana ovalada
    vw = int(lienzo_w * random.uniform(0.72, 0.86))
    vh = int(lienzo_h * random.uniform(0.42, 0.55))
    vx = (lienzo_w - vw) // 2 + random.randint(-20, 20)
    vy = int(lienzo_h * random.uniform(0.38, 0.48)) - vh // 2 + 40
    marco = color_aleatorio((30, 45, 90), 25)
    d.rounded_rectangle((vx - 6, vy - 6, vx + vw + 6, vy + vh + 6), radius=vh // 2 + 6, fill=marco)

    # Número de serie dorado grabado encima de la ventana (distractor)
    if random.random() < 0.75:
        serie = f"{random.randint(10, 99)} {random.randint(0, 999999):06d}m³"
        fuente_serie = ImageFont.truetype(random.choice(fuentes), random.randint(34, 52))
        d.text((vx + random.randint(-10, 40), max(0, vy - random.randint(70, 95))), serie,
               fill=color_aleatorio((185, 160, 95), 30), font=fuente_serie)

    # Rodillos: dentro del tramo recto de la ventana (los extremos redondos no tapan los dígitos)
    fondo_ventana = Image.new("RGB", (vw, vh), color_aleatorio((215, 215, 215), 20))
    inset = int(vh * random.uniform(0.18, 0.32))
    zona = Image.new("RGB", (vw - 2 * inset, vh), (235, 235, 235))
    tamano_fuente = int(vh * random.uniform(0.62, 0.8))
    fuente = ImageFont.truetype(random.choice(fuentes), tamano_fuente)
    ancho_celda = zona.width / DIGITOS
    separador = color_aleatorio((70, 70, 70), 30)
    blanco = color_aleatorio((238, 238, 236), 15)
    rojo = color_aleatorio((200, 30, 45), 25)
    for i, (digito, fraccion) in enumerate(rodillos):
        es_decimal = i >= DIGITOS_ENTEROS
        fondo = rojo if es_decimal else blanco
        tinta = color_aleatorio((250, 250, 250), 8) if es_decimal else color_aleatorio((20, 20, 25), 15)
        x0, x1 = int(i * ancho_celda), int((i + 1) * ancho_celda)
        celda = dibujar_rodillo(x1 - x0, vh, digito, fraccion, fondo, tinta, fuente)
        zona.paste(celda, (x0, 0))
        ImageDraw.Draw(zona).line((x0, 0, x0, vh), fill=separador, width=random.randint(1, 3))

    fondo_ventana.paste(zona, (inset, 0))
    mascara = Image.new("L", (vw, vh), 0)
    ImageDraw.Draw(mascara).rounded_rectangle((0, 0, vw - 1, vh - 1), radius=vh // 2, fill=255)
    imagen.paste(fondo_ventana, (vx, vy), mascara)

    # Reflejo del vidrio
    if random.random() < 0.6:
        reflejo = Image.new("L", (lienzo_w, lienzo_h), 0)
        rx = random.randint(vx, vx + vw)
        ImageDraw.Draw(reflejo).ellipse((rx - 60, vy - 10, rx + random.randint(30, 160), vy + vh // 2),
                                         fill=random.randint(40, 120))
        reflejo = reflejo.filter(ImageFilter.GaussianBlur(18))
        imagen = Image.composite(Image.new("RGB", imagen.size, (255, 255, 255)), imagen, reflejo)

    # Suciedad (manchas pequeñas)
    d = ImageDraw.Draw(imagen)
    for _ in range(random.randint(0, 8)):
        x, y = random.randint(vx, vx + vw), random.randint(vy, vy + vh)
        r = random.randint(1, 5)
        d.ellipse((x - r, y - r, x + r, y + r), fill=color_aleatorio((90, 70, 40), 40))

    # Inclinación y recorte holgado (como el recuadro guía de la app)
    imagen = imagen.rotate(random.uniform(-6, 6), resample=Image.BILINEAR, expand=False, fillcolor=carcasa)
    margen_x = vw * random.uniform(0.0, 0.12)
    margen_y = vh * random.uniform(0.05, 0.45)
    caja = (vx - margen_x + random.uniform(-10, 10), vy - margen_y + random.uniform(-8, 8),
            vx + vw + margen_x + random.uniform(-10, 10), vy + vh + margen_y + random.uniform(-8, 8))
    imagen = imagen.crop(tuple(int(v) for v in caja))

    # Desenfoque, brillo y contraste
    if random.random() < 0.5:
        imagen = imagen.filter(ImageFilter.GaussianBlur(random.uniform(0.3, 2.2)))
    arreglo = np.asarray(imagen).astype(np.float32)
    arreglo = arreglo * random.uniform(0.55, 1.25) + random.uniform(-35, 35)
    arreglo += np.random.normal(0, random.uniform(0, 12), arreglo.shape)
    imagen = Image.fromarray(np.clip(arreglo, 0, 255).astype(np.uint8))

    # Compresión JPEG (como las fotos del celular / WhatsApp)
    buffer = BytesIO()
    imagen.save(buffer, "JPEG", quality=random.randint(35, 90))
    imagen = Image.open(buffer)

    gris = imagen.convert("L").resize((ANCHO, ALTO), Image.BILINEAR)
    return np.asarray(gris, dtype=np.uint8), np.array(etiqueta(rodillos), dtype=np.uint8)


def generar_lote(argumentos):
    """Genera un lote en un proceso aparte (cada lote con su propia semilla)."""
    semilla, cantidad = argumentos
    random.seed(semilla)
    np.random.seed(semilla % (2 ** 32))
    fuentes = cargar_fuentes()
    X = np.zeros((cantidad, ALTO, ANCHO), dtype=np.uint8)
    y = np.zeros((cantidad, DIGITOS), dtype=np.uint8)
    for i in range(cantidad):
        X[i], y[i] = generar_muestra(fuentes)
    return X, y


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cantidad", type=int, default=60000)
    parser.add_argument("--semilla", type=int, default=7)
    parser.add_argument("--muestras-png", type=int, default=24, help="Guarda algunas imágenes para revisarlas")
    parser.add_argument("--procesos", type=int, default=max(1, (os.cpu_count() or 2) - 1))
    args = parser.parse_args()

    DATOS.mkdir(exist_ok=True)
    carpeta_png = DATOS / "muestras_sinteticas"
    carpeta_png.mkdir(exist_ok=True)

    tamano_lote = 2000
    lotes = [(args.semilla * 100003 + n, min(tamano_lote, args.cantidad - n * tamano_lote))
             for n in range((args.cantidad + tamano_lote - 1) // tamano_lote)]
    partes_X, partes_y = [], []
    with Pool(args.procesos) as pool:
        for X, y in pool.imap(generar_lote, lotes):
            partes_X.append(X)
            partes_y.append(y)
            print(f"  {sum(len(p) for p in partes_X)} / {args.cantidad} imágenes", flush=True)
    X, y = np.concatenate(partes_X), np.concatenate(partes_y)

    for i in range(min(args.muestras_png, len(X))):
        Image.fromarray(X[i]).save(carpeta_png / f"{i:03d}_{''.join(map(str, y[i]))}.png")
    np.savez_compressed(DATOS / "sinteticos.npz", X=X, y=y)
    print(f"Listo: {len(X)} imágenes en {DATOS / 'sinteticos.npz'}")


if __name__ == "__main__":
    main()

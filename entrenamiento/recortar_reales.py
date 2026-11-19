"""Recorta la ventanita del contador de cada foto real y la deja horizontal (enteros a la izquierda).

Lee etiquetas_reales.csv:
  archivo  : nombre de la foto en fotos_reales/
  lectura  : los 8 dígitos que muestra el contador (ej. 08136267 = 0813,6267 m³)
  x0..y1   : caja de la ventanita como fracción del ancho/alto de la foto (0 a 1)
  rotacion : grados para dejarla horizontal (0, 90 o -90; positivo = antihorario)

Uso:
  .venv\\Scripts\\python recortar_reales.py
Salida: datos/reales/<lectura>__<foto>.png  y  datos/reales_revision.png (todas juntas para revisar)
"""
import csv

from PIL import Image, ImageDraw, ImageOps

from comun import CARPETA, DATOS


def main():
    destino = DATOS / "reales"
    destino.mkdir(parents=True, exist_ok=True)
    for viejo in destino.glob("*__foto*.png"):
        viejo.unlink()

    recortes = []
    with open(CARPETA / "etiquetas_reales.csv", encoding="utf-8") as f:
        for i, fila in enumerate(csv.DictReader(f)):
            foto = ImageOps.exif_transpose(Image.open(CARPETA / "fotos_reales" / fila["archivo"])).convert("RGB")
            w, h = foto.size
            caja = tuple(int(float(fila[k]) * (w if k.startswith("x") else h)) for k in ("x0", "y0", "x1", "y1"))
            recorte = foto.crop(caja)
            if int(fila["rotacion"]):
                recorte = recorte.rotate(int(fila["rotacion"]), expand=True)
            nombre = f"{fila['lectura']}__foto{i + 1:02d}.png"
            recorte.save(destino / nombre)
            recortes.append((recorte, fila["lectura"], nombre))
            print(f"  {nombre}  {recorte.size}")

    # Hoja de revisión: cada recorte con la lectura que se le asignó
    alto_fila = 70
    hoja = Image.new("RGB", (560, alto_fila * len(recortes)), "white")
    d = ImageDraw.Draw(hoja)
    for i, (recorte, lectura, nombre) in enumerate(recortes):
        miniatura = recorte.resize((240, 60))
        hoja.paste(miniatura, (5, i * alto_fila + 5))
        d.text((260, i * alto_fila + 15), f"{lectura[:4]},{lectura[4:]}", fill="black")
        d.text((260, i * alto_fila + 35), nombre, fill="gray")
    hoja.save(DATOS / "reales_revision.png")
    print(f"Revise {DATOS / 'reales_revision.png'}")


if __name__ == "__main__":
    main()

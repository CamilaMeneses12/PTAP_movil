"""Descarga del celular (por USB) las lecturas confirmadas con la cámara y las suma a datos/reales.

En la app, cada vez que el operario toca "Usar valor", se guarda el recorte del contador con
su lectura correcta en el celular. Este script los trae al PC para volver a entrenar.

Requisitos: celular conectado por USB con "Depuración USB" activada (igual que para flutter run).
Uso:
  .venv\\Scripts\\python descargar_dataset_celular.py
"""
import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image

from comun import DATOS, DIGITOS

PAQUETE = "com.example.planta_agua"
RUTA_CELULAR = f"/sdcard/Android/data/{PAQUETE}/files/dataset_medidores"


def buscar_adb():
    candidatos = [
        shutil.which("adb"),
        Path(os.environ.get("LOCALAPPDATA", "")) / "Android" / "Sdk" / "platform-tools" / "adb.exe",
        Path(os.environ.get("ANDROID_HOME", "")) / "platform-tools" / "adb.exe",
    ]
    for c in candidatos:
        if c and Path(c).exists():
            return str(c)
    raise SystemExit("No se encontró adb. Instale Android SDK Platform-Tools.")


def main():
    adb = buscar_adb()
    destino_crudo = DATOS / "celular"
    destino_crudo.mkdir(parents=True, exist_ok=True)
    print(f"Descargando {RUTA_CELULAR} ...")
    resultado = subprocess.run([adb, "pull", RUTA_CELULAR, str(destino_crudo)], capture_output=True, text=True)
    print(resultado.stdout.strip() or resultado.stderr.strip())

    reales = DATOS / "reales"
    reales.mkdir(parents=True, exist_ok=True)
    nuevos = 0
    for archivo in destino_crudo.rglob("*.jpg"):
        digitos = archivo.stem.split("__")[0]
        if len(digitos) != DIGITOS or not digitos.isdigit():
            continue
        salida = reales / f"{digitos}__cel_{archivo.stem.split('__', 1)[1]}.png"
        if salida.exists():
            continue
        Image.open(archivo).save(salida)
        nuevos += 1
    total = len(list(reales.glob("*.png")))
    print(f"{nuevos} lecturas nuevas del celular. Total de fotos reales: {total}")
    print("Siguiente paso:  .venv\\Scripts\\python entrenar.py --con-reales")


if __name__ == "__main__":
    main()

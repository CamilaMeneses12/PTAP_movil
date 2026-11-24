@echo off
rem Genera imagenes sinteticas y entrena el lector de micromedidores (ver README.md)
cd /d "%~dp0"
set PYTHONIOENCODING=utf-8
set TF_CPP_MIN_LOG_LEVEL=2
.venv\Scripts\python.exe -u recortar_reales.py || exit /b 1
.venv\Scripts\python.exe -u generar_sinteticos.py --cantidad 60000 --semilla 21 || exit /b 1
.venv\Scripts\python.exe -u entrenar.py --epocas 20 %*

import numpy as np, tensorflow as tf, time
L = tf.keras.layers
from comun import DATOS, ALTO, ANCHO
d = np.load(DATOS / "sinteticos.npz")
X = d["X"][:1500].astype(np.float32)[..., None] / 255.0
y = d["y"][:1500].astype(np.int32)

def cabeza(x):
    x = L.Dense(8 * 10)(x); x = L.Reshape((8, 10))(x); return L.Softmax(-1)(x)

def sin_bn():
    i = tf.keras.Input((ALTO, ANCHO, 1)); x = i
    for f in (32, 64, 128):
        x = L.Conv2D(f, 3, padding="same", activation="relu")(x); x = L.MaxPooling2D(2)(x)
    x = L.Flatten()(x); x = L.Dense(256, activation="relu")(x)
    return tf.keras.Model(i, cabeza(x))

def columnas():
    # Reduce la altura a 1 y deja una fila de 24 columnas; cada dígito sale de su zona
    i = tf.keras.Input((ALTO, ANCHO, 1)); x = i
    for f, p in ((32, (2, 2)), (64, (2, 2)), (128, (2, 2)), (128, (6, 1))):
        x = L.Conv2D(f, 3, padding="same", activation="relu")(x); x = L.MaxPooling2D(p)(x)
    x = L.Reshape((24, 128))(x)                       # 24 columnas
    x = L.Conv1D(128, 3, padding="same", activation="relu")(x)
    x = L.Flatten()(x)
    return tf.keras.Model(i, cabeza(x))

def logits():
    # Igual que sin_bn pero con la pérdida calculada desde logits (más estable numéricamente)
    i = tf.keras.Input((ALTO, ANCHO, 1)); x = i
    for f in (32, 64, 128):
        x = L.Conv2D(f, 3, padding="same", activation="relu")(x); x = L.MaxPooling2D(2)(x)
    x = L.Flatten()(x); x = L.Dense(256, activation="relu")(x)
    x = L.Dense(80)(x); x = L.Reshape((8, 10))(x)
    return tf.keras.Model(i, x)

for nombre, f, desde_logits in (("sin_bn", sin_bn, False), ("columnas", columnas, False), ("logits", logits, True)):
    m = f()
    m.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
              loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=desde_logits),
              metrics=[tf.keras.metrics.SparseCategoricalAccuracy(name="acc")])
    t = time.time()
    h = m.fit(X, y, epochs=6, batch_size=32, verbose=0)
    print(f"{nombre:9s} acierto memorizando por época: {[round(a*100) for a in h.history['acc']]}  ({time.time()-t:.0f} s)", flush=True)

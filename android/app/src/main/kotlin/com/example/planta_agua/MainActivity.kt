package com.example.planta_agua

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Pantalla de Flutter (login y el resto de la app). Usa el motor que AppPtap ya arrancó
 * mientras se veía el video, así no hay espera al entrar.
 */
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine =
        (applicationContext as AppPtap).motor()

    // El motor vive con la app, no con esta pantalla: si Android la recrea, la app sigue igual.
    override fun shouldDestroyEngineWithHost(): Boolean = false
}

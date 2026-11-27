package com.example.planta_agua

import android.app.Application
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Prepara Flutter por detrás mientras InicioActivity muestra el video de bienvenida.
 *
 * 1. Al abrir la app solo se empiezan a cargar los archivos de Flutter en segundo plano
 *    (no frena la pantalla del video).
 * 2. Cuando el video ya se ve, InicioActivity llama a [prepararMotor]: se crea el motor y
 *    corre main() (Supabase, fechas, datos guardados), así el login queda listo.
 * 3. MainActivity usa ese mismo motor y el login aparece de inmediato.
 */
class AppPtap : Application() {
    companion object {
        const val ID_MOTOR = "motor_principal"
    }

    override fun onCreate() {
        super.onCreate()
        FlutterInjector.instance().flutterLoader().startInitialization(this)
    }

    /** Crea el motor cuando terminen de cargar los archivos de Flutter, sin bloquear la pantalla. */
    fun prepararMotor() {
        if (FlutterEngineCache.getInstance().contains(ID_MOTOR)) return
        FlutterInjector.instance().flutterLoader()
            .ensureInitializationCompleteAsync(this, null, Handler(Looper.getMainLooper())) { motor() }
    }

    /** Devuelve el motor de Flutter, creándolo y arrancando main() si aún no existe. */
    fun motor(): FlutterEngine {
        FlutterEngineCache.getInstance().get(ID_MOTOR)?.let { return it }
        val motor = FlutterEngine(this)
        motor.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ID_MOTOR, motor)
        return motor
    }
}

package com.example.planta_agua

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.SurfaceTexture
import android.graphics.drawable.GradientDrawable
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.Surface
import android.view.TextureView
import android.widget.FrameLayout
import android.widget.TextView

/**
 * Pantalla de bienvenida nativa: reproduce res/raw/animacion.mp4 apenas se toca el ícono,
 * sin esperar a Flutter. Dura 4 s (o menos si se toca la pantalla o "Omitir") y luego abre
 * MainActivity, cuyo motor de Flutter ya se preparó durante el video (ver AppPtap).
 */
class InicioActivity : Activity(), TextureView.SurfaceTextureListener {
    companion object {
        private const val DURACION_MS = 4_000L      // se corta a los 4 s aunque el archivo dure más
        private const val LIMITE_MS = 6_000L        // por si el video no se puede reproducir
        private const val ESCALA = 0.65f            // parte de la pantalla que ocupa el video
        private val FONDO = Color.parseColor("#F2F2F2") // mismo gris del video y de la app
    }

    private val manejador = Handler(Looper.getMainLooper())
    private var reproductor: MediaPlayer? = null
    private lateinit var lienzo: TextureView
    private lateinit var contenedor: FrameLayout
    private var terminado = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        contenedor = FrameLayout(this).apply {
            setBackgroundColor(FONDO)
            setOnClickListener { terminar() }
        }

        // TextureView (no VideoView) para que no se vea un recuadro negro antes del primer cuadro.
        lienzo = TextureView(this).apply {
            alpha = 0f
            surfaceTextureListener = this@InicioActivity
        }
        contenedor.addView(lienzo, FrameLayout.LayoutParams(1, 1, Gravity.CENTER))

        val omitir = TextView(this).apply {
            text = "Omitir"
            setTextColor(Color.WHITE)
            textSize = 14f
            val dp = resources.displayMetrics.density
            setPadding((16 * dp).toInt(), (8 * dp).toInt(), (16 * dp).toInt(), (8 * dp).toInt())
            background = GradientDrawable().apply {
                setColor(Color.argb(90, 0, 0, 0))
                cornerRadius = 20 * dp
            }
            setOnClickListener { terminar() }
        }
        val margen = (24 * resources.displayMetrics.density).toInt()
        contenedor.addView(
            omitir,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.END or Gravity.BOTTOM,
            ).apply { setMargins(0, 0, margen, margen * 2) },
        )

        setContentView(contenedor)
        manejador.postDelayed({ terminar() }, LIMITE_MS)
        // Respaldo: si el video tarda o falla, Flutter igual se prepara a los 1,5 s.
        manejador.postDelayed({ (application as AppPtap).prepararMotor() }, 1_500L)
    }

    override fun onSurfaceTextureAvailable(textura: SurfaceTexture, ancho: Int, alto: Int) {
        val superficie = Surface(textura)
        try {
            reproductor = MediaPlayer().apply {
                setDataSource(this@InicioActivity, Uri.parse("android.resource://$packageName/${R.raw.animacion}"))
                setSurface(superficie)
                setVolume(0f, 0f)
                setOnPreparedListener { mp ->
                    ajustarTamano(mp.videoWidth, mp.videoHeight)
                    mp.start()
                    manejador.removeCallbacksAndMessages(null)
                    manejador.postDelayed({ terminar() }, DURACION_MS)
                }
                setOnInfoListener { _, que, _ ->
                    // Se muestra solo cuando ya hay imagen: nunca un recuadro vacío.
                    if (que == MediaPlayer.MEDIA_INFO_VIDEO_RENDERING_START) {
                        lienzo.alpha = 1f
                        // El video ya se ve: ahora sí se prepara Flutter (login) por detrás.
                        (application as AppPtap).prepararMotor()
                    }
                    false
                }
                setOnCompletionListener { terminar() }
                setOnErrorListener { _, _, _ -> terminar(); true }
                prepareAsync()
            }
        } catch (e: Exception) {
            terminar()
        }
    }

    /** El video ocupa el 65 % de la pantalla, centrado y sin deformarse. */
    private fun ajustarTamano(anchoVideo: Int, altoVideo: Int) {
        if (anchoVideo <= 0 || altoVideo <= 0) return
        val maxAncho = contenedor.width * ESCALA
        val maxAlto = contenedor.height * ESCALA
        val factor = minOf(maxAncho / anchoVideo, maxAlto / altoVideo)
        lienzo.layoutParams = FrameLayout.LayoutParams(
            (anchoVideo * factor).toInt(),
            (altoVideo * factor).toInt(),
            Gravity.CENTER,
        )
    }

    private fun terminar() {
        if (terminado) return
        terminado = true
        manejador.removeCallbacksAndMessages(null)
        startActivity(Intent(this, MainActivity::class.java))
        finish()
        // Sin animación de cambio de pantalla: del video se pasa directo al login.
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    override fun onSurfaceTextureSizeChanged(textura: SurfaceTexture, ancho: Int, alto: Int) {}

    override fun onSurfaceTextureDestroyed(textura: SurfaceTexture): Boolean = true

    override fun onSurfaceTextureUpdated(textura: SurfaceTexture) {}

    override fun onDestroy() {
        manejador.removeCallbacksAndMessages(null)
        reproductor?.release()
        reproductor = null
        super.onDestroy()
    }
}

package com.example.mirrorscreen

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mirrorscreen/capture"
    private val REQUEST_CODE = 1000
    
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var resultCode: Int = 0
    private var resultData: Intent? = null
    
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) 
            as MediaProjectionManager
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    requestScreenCapturePermission()
                    result.success(true)
                }
                "startCapture" -> {
                    startScreenCapture()
                    result.success(true)
                }
                "stopCapture" -> {
                    stopScreenCapture()
                    result.success(true)
                }
                "captureScreen" -> {
                    val screenshot = captureScreenshot()
                    result.success(screenshot)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestScreenCapturePermission() {
        // IMPORTANT: Démarrer le service AVANT de demander la permission
        val serviceIntent = Intent(this, ScreenMirrorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        
        // Délai plus long pour Android 14+ pour s'assurer que le service est bien en foreground
        val delay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) 500L else 200L
        Handler(Looper.getMainLooper()).postDelayed({
            val captureIntent = mediaProjectionManager?.createScreenCaptureIntent()
            startActivityForResult(captureIntent, REQUEST_CODE)
        }, delay)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                this.resultCode = resultCode
                this.resultData = data
                // Attendre que le service soit bien en foreground (plus long pour Android 14+)
                val delay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) 500L else 300L
                Handler(Looper.getMainLooper()).postDelayed({
                    setupMediaProjection()
                }, delay)
            } else {
                // Permission refusée, arrêter le service
                val serviceIntent = Intent(this, ScreenMirrorService::class.java)
                stopService(serviceIntent)
            }
        }
    }

    private fun setupMediaProjection() {
        try {
            mediaProjection = mediaProjectionManager?.getMediaProjection(
                resultCode,
                resultData!!
            )
            
            // IMPORTANT: Enregistrer le callback AVANT de créer le VirtualDisplay (Android 14+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                    override fun onStop() {
                        super.onStop()
                        cleanupMediaProjection()
                    }
                    
                    override fun onCapturedContentResize(width: Int, height: Int) {
                        super.onCapturedContentResize(width, height)
                        // Optionnel: gérer le redimensionnement
                    }
                    
                    override fun onCapturedContentVisibilityChanged(isVisible: Boolean) {
                        super.onCapturedContentVisibilityChanged(isVisible)
                        // Optionnel: gérer la visibilité
                    }
                }, Handler(Looper.getMainLooper()))
            }
            
            val metrics = DisplayMetrics()
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                windowManager.defaultDisplay?.getMetrics(metrics)
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getMetrics(metrics)
            }
            
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi
            
            imageReader = ImageReader.newInstance(
                width,
                height,
                PixelFormat.RGBA_8888,
                2
            )
            
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenMirror",
                width,
                height,
                density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null,
                null
            )
        } catch (e: Exception) {
            e.printStackTrace()
            // Arrêter le service en cas d'erreur
            val serviceIntent = Intent(this, ScreenMirrorService::class.java)
            stopService(serviceIntent)
        }
    }
    
    private fun cleanupMediaProjection() {
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
    }

    private fun startScreenCapture() {
        if (mediaProjection == null) {
            requestScreenCapturePermission()
        }
    }

    private fun stopScreenCapture() {
        cleanupMediaProjection()
        mediaProjection?.stop()
        mediaProjection = null
        
        // Arrêter le service foreground
        val serviceIntent = Intent(this, ScreenMirrorService::class.java)
        stopService(serviceIntent)
    }

    private fun captureScreenshot(): ByteArray? {
        return try {
            val image = imageReader?.acquireLatestImage()
            if (image != null) {
                val planes = image.planes
                val buffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * image.width
                
                val bitmap = Bitmap.createBitmap(
                    image.width + rowPadding / pixelStride,
                    image.height,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(buffer)
                image.close()
                
                // Convertir en ByteArray
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                val byteArray = stream.toByteArray()
                bitmap.recycle()
                
                byteArray
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun onDestroy() {
        stopScreenCapture()
        super.onDestroy()
    }
}
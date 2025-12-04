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
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mirrorscreen/capture"
    private val REQUEST_CODE = 1000
    private val TAG = "MirrorScreen"
    
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    
    // IMPORTANT: Ne pas stocker resultCode/resultData pour Android 14+
    private var pendingResultCode: Int = 0
    private var pendingResultData: Intent? = null
    private var isPermissionGranted = false
    
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
                    if (isPermissionGranted) {
                        startScreenCapture()
                        result.success(true)
                    } else {
                        result.error("NO_PERMISSION", "Permission non accordée", null)
                    }
                }
                "stopCapture" -> {
                    stopScreenCapture()
                    result.success(true)
                }
                "captureScreen" -> {
                    val screenshot = captureScreenshot()
                    if (screenshot != null) {
                        result.success(screenshot)
                    } else {
                        result.error("CAPTURE_FAILED", "Échec de la capture", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestScreenCapturePermission() {
        Log.d(TAG, "Demande de permission de capture d'écran")
        
        // Démarrer le service AVANT de demander la permission
        val serviceIntent = Intent(this, ScreenMirrorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        
        // Délai pour s'assurer que le service est en foreground
        val delay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) 800L else 300L
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val captureIntent = mediaProjectionManager?.createScreenCaptureIntent()
                if (captureIntent != null) {
                    startActivityForResult(captureIntent, REQUEST_CODE)
                } else {
                    Log.e(TAG, "Impossible de créer l'intent de capture")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erreur lors de la demande de permission", e)
            }
        }, delay)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d(TAG, "Permission accordée")
                
                // Stocker temporairement pour une SEULE utilisation
                pendingResultCode = resultCode
                pendingResultData = data
                isPermissionGranted = true
                
                // Attendre que le service soit stable
                val delay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) 1000L else 500L
                Handler(Looper.getMainLooper()).postDelayed({
                    setupMediaProjection()
                }, delay)
            } else {
                Log.e(TAG, "Permission refusée")
                isPermissionGranted = false
                stopService(Intent(this, ScreenMirrorService::class.java))
            }
        }
    }

    private fun setupMediaProjection() {
        if (!isPermissionGranted || pendingResultData == null) {
            Log.e(TAG, "Pas de permission valide")
            return
        }
        
        try {
            Log.d(TAG, "Configuration de MediaProjection")
            
            // Créer MediaProjection une seule fois
            mediaProjection = mediaProjectionManager?.getMediaProjection(
                pendingResultCode,
                pendingResultData!!
            )
            
            // IMPORTANT: NE PLUS utiliser pendingResultData après cette création
            pendingResultData = null
            
            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection est null")
                return
            }
            
            // Enregistrer le callback AVANT de créer le VirtualDisplay (Android 14+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                    override fun onStop() {
                        super.onStop()
                        Log.d(TAG, "MediaProjection arrêtée")
                        cleanupMediaProjection()
                    }
                }, Handler(Looper.getMainLooper()))
            }
            
            // Obtenir les métriques de l'écran
            val metrics = getScreenMetrics()
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi
            
            Log.d(TAG, "Résolution: ${width}x${height}, densité: $density")
            
            // Créer ImageReader avec un format compatible
            imageReader = ImageReader.newInstance(
                width,
                height,
                PixelFormat.RGBA_8888,
                2
            )
            
            // Créer VirtualDisplay
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
            
            if (virtualDisplay != null) {
                Log.d(TAG, "VirtualDisplay créé avec succès")
            } else {
                Log.e(TAG, "Échec de création du VirtualDisplay")
            }
            
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException lors de la création de MediaProjection", e)
            // Cette erreur indique une réutilisation de resultData
            isPermissionGranted = false
            stopService(Intent(this, ScreenMirrorService::class.java))
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la configuration", e)
            stopService(Intent(this, ScreenMirrorService::class.java))
        }
    }
    
    private fun getScreenMetrics(): DisplayMetrics {
        val metrics = DisplayMetrics()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = windowManager.currentWindowMetrics.bounds
            metrics.widthPixels = bounds.width()
            metrics.heightPixels = bounds.height()
            metrics.densityDpi = resources.displayMetrics.densityDpi
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getMetrics(metrics)
        }
        
        return metrics
    }
    
    private fun cleanupMediaProjection() {
        Log.d(TAG, "Nettoyage des ressources")
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
    }

    private fun startScreenCapture() {
        if (mediaProjection == null) {
            Log.w(TAG, "MediaProjection null, nouvelle demande de permission")
            requestScreenCapturePermission()
        } else {
            Log.d(TAG, "Capture déjà active")
        }
    }

    private fun stopScreenCapture() {
        Log.d(TAG, "Arrêt de la capture")
        cleanupMediaProjection()
        mediaProjection?.stop()
        mediaProjection = null
        isPermissionGranted = false
        
        stopService(Intent(this, ScreenMirrorService::class.java))
    }

    private fun captureScreenshot(): ByteArray? {
        return try {
            val image = imageReader?.acquireLatestImage()
            if (image != null) {
                val planes = image.planes
                if (planes.isEmpty()) {
                    Log.e(TAG, "Pas de planes disponibles")
                    image.close()
                    return null
                }
                
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
                
                // Convertir en ByteArray avec compression JPEG
                val stream = ByteArrayOutputStream()
                val compressed = bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                
                if (!compressed) {
                    Log.e(TAG, "Échec de compression de l'image")
                    bitmap.recycle()
                    return null
                }
                
                val byteArray = stream.toByteArray()
                bitmap.recycle()
                
                Log.d(TAG, "Screenshot capturé: ${byteArray.size} bytes")
                byteArray
            } else {
                Log.w(TAG, "Aucune image disponible")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la capture", e)
            null
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy appelé")
        stopScreenCapture()
        super.onDestroy()
    }
}
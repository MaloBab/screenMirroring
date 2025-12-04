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
    
    private var pendingResultCode: Int = 0
    private var pendingResultData: Intent? = null
    private var isPermissionGranted = false
    
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "🔧 Configuration du FlutterEngine")
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) 
            as MediaProjectionManager
        
        Log.d(TAG, "✅ MediaProjectionManager initialisé")
        
        methodChannel.setMethodCallHandler { call, result ->
            Log.d(TAG, "📱 Méthode appelée: ${call.method}")
            
            when (call.method) {
                "requestPermission" -> {
                    Log.d(TAG, "🔐 Demande de permission reçue")
                    requestScreenCapturePermission()
                    result.success(true)
                }
                "startCapture" -> {
                    Log.d(TAG, "🎬 Demande de démarrage de capture")
                    if (isPermissionGranted) {
                        startScreenCapture()
                        result.success(true)
                    } else {
                        Log.e(TAG, "❌ Permission non accordée")
                        result.error("NO_PERMISSION", "Permission non accordée", null)
                    }
                }
                "stopCapture" -> {
                    Log.d(TAG, "🛑 Demande d'arrêt de capture")
                    stopScreenCapture()
                    result.success(true)
                }
                "captureScreen" -> {
                    val screenshot = captureScreenshot()
                    if (screenshot != null) {
                        Log.d(TAG, "📸 Screenshot capturé: ${screenshot.size} bytes")
                        result.success(screenshot)
                    } else {
                        Log.e(TAG, "❌ Échec capture screenshot")
                        result.error("CAPTURE_FAILED", "Échec de la capture", null)
                    }
                }
                else -> {
                    Log.w(TAG, "⚠️ Méthode non implémentée: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        Log.d(TAG, "✅ MethodChannel configuré")
    }

    private fun requestScreenCapturePermission() {
        Log.d(TAG, "🚀 Démarrage du processus de demande de permission")
        
        // Démarrer le service AVANT de demander la permission
        val serviceIntent = Intent(this, ScreenMirrorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "📱 Android O+ détecté, utilisation de startForegroundService")
            startForegroundService(serviceIntent)
        } else {
            Log.d(TAG, "📱 Android < O, utilisation de startService")
            startService(serviceIntent)
        }
        
        // Délai pour s'assurer que le service est en foreground
        val delay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Log.d(TAG, "⏱️ Android 14+ détecté, délai de 800ms")
            800L
        } else {
            Log.d(TAG, "⏱️ Android < 14, délai de 300ms")
            300L
        }
        
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                Log.d(TAG, "🎯 Création de l'intent de capture d'écran")
                val captureIntent = mediaProjectionManager?.createScreenCaptureIntent()
                
                if (captureIntent != null) {
                    Log.d(TAG, "✅ Intent créé, lancement de l'activité")
                    startActivityForResult(captureIntent, REQUEST_CODE)
                    Log.d(TAG, "📲 Popup de permission Android devrait apparaître maintenant")
                } else {
                    Log.e(TAG, "❌ Impossible de créer l'intent de capture")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erreur lors de la demande de permission", e)
            }
        }, delay)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        Log.d(TAG, "📥 onActivityResult appelé")
        Log.d(TAG, "   requestCode: $requestCode")
        Log.d(TAG, "   resultCode: $resultCode")
        Log.d(TAG, "   data: ${if (data != null) "présent" else "null"}")
        
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d(TAG, "✅ Permission accordée par l'utilisateur")
                
                // Stocker temporairement pour une SEULE utilisation
                pendingResultCode = resultCode
                pendingResultData = data
                isPermissionGranted = true
                
                Log.d(TAG, "💾 Données de permission stockées")
                
                // Attendre que le service soit stable
                val delay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    Log.d(TAG, "⏱️ Délai de stabilisation: 1000ms")
                    1000L
                } else {
                    Log.d(TAG, "⏱️ Délai de stabilisation: 500ms")
                    500L
                }
                
                Handler(Looper.getMainLooper()).postDelayed({
                    Log.d(TAG, "🎬 Configuration de MediaProjection après délai")
                    setupMediaProjection()
                }, delay)
            } else {
                Log.e(TAG, "❌ Permission refusée par l'utilisateur")
                Log.e(TAG, "   resultCode était: $resultCode (RESULT_OK=${Activity.RESULT_OK})")
                isPermissionGranted = false
                stopService(Intent(this, ScreenMirrorService::class.java))
            }
        } else {
            Log.w(TAG, "⚠️ Code de requête non reconnu: $requestCode")
        }
    }

    private fun setupMediaProjection() {
        Log.d(TAG, "⚙️ Début de setupMediaProjection")
        
        if (!isPermissionGranted || pendingResultData == null) {
            Log.e(TAG, "❌ Pas de permission valide")
            Log.e(TAG, "   isPermissionGranted: $isPermissionGranted")
            Log.e(TAG, "   pendingResultData: ${if (pendingResultData != null) "présent" else "null"}")
            return
        }
        
        try {
            Log.d(TAG, "🎥 Création de MediaProjection")
            
            // Créer MediaProjection une seule fois
            mediaProjection = mediaProjectionManager?.getMediaProjection(
                pendingResultCode,
                pendingResultData!!
            )
            
            // IMPORTANT: NE PLUS utiliser pendingResultData après cette création
            pendingResultData = null
            Log.d(TAG, "🗑️ pendingResultData effacé (usage unique)")
            
            if (mediaProjection == null) {
                Log.e(TAG, "❌ MediaProjection est null après création")
                return
            }
            
            Log.d(TAG, "✅ MediaProjection créée avec succès")
            
            // Enregistrer le callback AVANT de créer le VirtualDisplay (Android 14+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                Log.d(TAG, "📝 Enregistrement du callback MediaProjection (Android 14+)")
                mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                    override fun onStop() {
                        super.onStop()
                        Log.d(TAG, "🛑 MediaProjection arrêtée (callback)")
                        cleanupMediaProjection()
                    }
                }, Handler(Looper.getMainLooper()))
            }
            
            // Obtenir les métriques de l'écran
            val metrics = getScreenMetrics()
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi
            
            Log.d(TAG, "📏 Résolution écran: ${width}x${height}, densité: $density")
            
            // Créer ImageReader avec un format compatible
            Log.d(TAG, "🖼️ Création de ImageReader")
            imageReader = ImageReader.newInstance(
                width,
                height,
                PixelFormat.RGBA_8888,
                2
            )
            Log.d(TAG, "✅ ImageReader créé")
            
            // Créer VirtualDisplay
            Log.d(TAG, "🖥️ Création de VirtualDisplay")
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
                Log.d(TAG, "✅✅✅ VirtualDisplay créé avec succès - CAPTURE ACTIVE ✅✅✅")
            } else {
                Log.e(TAG, "❌ Échec de création du VirtualDisplay")
            }
            
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException lors de la création de MediaProjection", e)
            Log.e(TAG, "   Cette erreur indique une réutilisation de resultData")
            isPermissionGranted = false
            stopService(Intent(this, ScreenMirrorService::class.java))
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur lors de la configuration", e)
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
        Log.d(TAG, "🧹 Nettoyage des ressources")
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
        Log.d(TAG, "✅ Ressources nettoyées")
    }

    private fun startScreenCapture() {
        Log.d(TAG, "▶️ startScreenCapture appelé")
        if (mediaProjection == null) {
            Log.w(TAG, "⚠️ MediaProjection null, nouvelle demande de permission")
            requestScreenCapturePermission()
        } else {
            Log.d(TAG, "✅ Capture déjà active")
        }
    }

    private fun stopScreenCapture() {
        Log.d(TAG, "⏹️ Arrêt de la capture")
        cleanupMediaProjection()
        mediaProjection?.stop()
        mediaProjection = null
        isPermissionGranted = false
        
        stopService(Intent(this, ScreenMirrorService::class.java))
        Log.d(TAG, "✅ Capture arrêtée")
    }

    private fun captureScreenshot(): ByteArray? {
        return try {
            val image = imageReader?.acquireLatestImage()
            if (image != null) {
                val planes = image.planes
                if (planes.isEmpty()) {
                    Log.e(TAG, "❌ Pas de planes disponibles")
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
                    Log.e(TAG, "❌ Échec de compression de l'image")
                    bitmap.recycle()
                    return null
                }
                
                val byteArray = stream.toByteArray()
                bitmap.recycle()
                
                byteArray
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur lors de la capture", e)
            null
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "💀 onDestroy appelé")
        stopScreenCapture()
        super.onDestroy()
    }
}
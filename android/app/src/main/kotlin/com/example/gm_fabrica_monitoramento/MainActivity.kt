package com.example.gm_fabrica_monitoramento

import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "GmNativeAudio"
        private const val AUDIO_CHANNEL_NAME = "com.gm_fabrica/native_audio"
        private const val WAKELOCK_CHANNEL_NAME = "com.gm_fabrica/kiosk_wakelock"
        private const val MAX_STREAMS = 16
    }

    private var soundPool: SoundPool? = null
    private val assetToSoundId = ConcurrentHashMap<String, Int>()
    private val loadedSoundIds = ConcurrentHashMap.newKeySet<Int>()
    private val pendingPlaySoundIds = ConcurrentHashMap.newKeySet<Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enforceWakeLockFlags()

        // Enable true edge-to-edge game-style rendering across camera cutouts/notches
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun onResume() {
        super.onResume()
        enforceWakeLockFlags()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            enforceWakeLockFlags()
        }
    }

    private fun enforceWakeLockFlags() {
        // Keep screen awake at all times on the factory wall kiosk across all views
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.decorView.keepScreenOn = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        enforceWakeLockFlags()
        initSoundPool()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableWakeLock" -> {
                        runOnUiThread { enforceWakeLockFlags() }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "preload" -> {
                        val assets = call.argument<List<String>>("assets") ?: emptyList()
                        val count = preloadAssets(assets)
                        result.success(count)
                    }
                    "play" -> {
                        val asset = call.argument<String>("asset")
                        if (asset.isNullOrEmpty()) {
                            result.error("INVALID_ARG", "Asset path is required", null)
                        } else {
                            val ok = playAsset(asset)
                            result.success(ok)
                        }
                    }
                    "reset" -> {
                        val assets = call.argument<List<String>>("assets") ?: emptyList()
                        releaseSoundPool()
                        initSoundPool()
                        val count = preloadAssets(assets)
                        result.success(count)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initSoundPool() {
        if (soundPool != null) return

        // Use USAGE_MEDIA + CONTENT_TYPE_SONIFICATION without requesting AudioFocus.
        // This guarantees sounds always play over the Media volume slider and never
        // deadlock or get muted by Do Not Disturb / notification focus rules during 18h+ runs.
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(MAX_STREAMS)
            .setAudioAttributes(attributes)
            .build()
            .apply {
                setOnLoadCompleteListener { pool, sampleId, status ->
                    if (status == 0) {
                        loadedSoundIds.add(sampleId)
                        if (pendingPlaySoundIds.remove(sampleId)) {
                            pool.play(sampleId, 1.0f, 1.0f, 1, 0, 1.0f)
                        }
                    } else {
                        Log.w(TAG, "Failed to load soundId=$sampleId (status=$status)")
                        pendingPlaySoundIds.remove(sampleId)
                    }
                }
            }
    }

    private fun preloadAssets(assets: List<String>): Int {
        initSoundPool()
        var loadedCount = 0
        for (asset in assets) {
            if (getOrLoadSoundId(asset) != null) {
                loadedCount++
            }
        }
        return loadedCount
    }

    private fun getOrLoadSoundId(flutterAssetPath: String): Int? {
        assetToSoundId[flutterAssetPath]?.let { return it }
        val pool = soundPool ?: return null

        return try {
            val lookupKey = FlutterInjector.instance()
                .flutterLoader()
                .getLookupKeyForAsset("assets/$flutterAssetPath")
            assets.openFd(lookupKey).use { afd ->
                val soundId = pool.load(afd, 1)
                if (soundId != 0) {
                    assetToSoundId[flutterAssetPath] = soundId
                    soundId
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading asset assets/$flutterAssetPath: ${e.message}")
            null
        }
    }

    private fun playAsset(flutterAssetPath: String): Boolean {
        initSoundPool()
        val pool = soundPool ?: return false
        val soundId = getOrLoadSoundId(flutterAssetPath) ?: return false

        return if (loadedSoundIds.contains(soundId)) {
            val streamId = pool.play(soundId, 1.0f, 1.0f, 1, 0, 1.0f)
            if (streamId == 0) {
                Log.w(TAG, "SoundPool.play returned streamId=0 for $flutterAssetPath")
            }
            streamId != 0
        } else {
            // Sound is still decoding into RAM; queue it to play immediately on load complete
            pendingPlaySoundIds.add(soundId)
            true
        }
    }

    private fun releaseSoundPool() {
        pendingPlaySoundIds.clear()
        loadedSoundIds.clear()
        assetToSoundId.clear()
        try {
            soundPool?.release()
        } catch (_: Exception) {
        }
        soundPool = null
    }

    override fun onDestroy() {
        releaseSoundPool()
        super.onDestroy()
    }
}

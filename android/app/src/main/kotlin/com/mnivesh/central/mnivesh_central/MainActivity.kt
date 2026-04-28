package com.mnivesh.central.mnivesh_central

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val galleryChannel = "com.mnivesh.central.mnivesh_central/gallery"
    private val authCallbackScheme = "mniveshcentral"
    private val authCallbackHost = "auth"
    private val authCallbackPath = "/callback"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        if (isAuthCallbackIntent(intent)) {
            window.decorView.post {
                clearConsumedAuthCallbackIntent()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            galleryChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImage" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val title = call.argument<String>("title")

                    if (bytes == null || title.isNullOrBlank()) {
                        result.error(
                            "invalid_args",
                            "Image bytes and title are required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val savedPath = saveImageToGallery(bytes, title)
                        result.success(savedPath)
                    } catch (error: Exception) {
                        result.error("save_failed", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    @Throws(IOException::class)
    private fun saveImageToGallery(bytes: ByteArray, title: String): String {
        val safeTitle = title.trim().ifEmpty { "marketing_template" }
        val fileName = "${safeTitle}_${System.currentTimeMillis()}.png"
        val resolver = applicationContext.contentResolver
        val relativePath = "${Environment.DIRECTORY_PICTURES}/mNivesh Central"
        val legacyPicturesDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_PICTURES,
        ).resolve("mNivesh Central").apply {
            if (!exists()) {
                mkdirs()
            }
        }

        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)
                put(MediaStore.Images.Media.IS_PENDING, 1)
            } else {
                put(
                    MediaStore.Images.Media.DATA,
                    legacyPicturesDir.resolve(fileName).absolutePath,
                )
            }
        }

        val collection =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }

        val uri = resolver.insert(collection, values)
            ?: throw IOException("Failed to create MediaStore record.")

        try {
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: throw IOException("Failed to open gallery output stream.")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }

        return uri.toString()
    }

    private fun isAuthCallbackIntent(intent: Intent?): Boolean {
        val data = intent?.data ?: return false
        return data.scheme == authCallbackScheme &&
            data.host == authCallbackHost &&
            data.path == authCallbackPath
    }

    private fun clearConsumedAuthCallbackIntent() {
        if (!isAuthCallbackIntent(intent)) {
            return
        }

        val clearedIntent = Intent(intent).apply {
            data = null
            action = Intent.ACTION_MAIN
            removeCategory(Intent.CATEGORY_BROWSABLE)
            removeCategory(Intent.CATEGORY_DEFAULT)
        }

        setIntent(clearedIntent)
    }
}

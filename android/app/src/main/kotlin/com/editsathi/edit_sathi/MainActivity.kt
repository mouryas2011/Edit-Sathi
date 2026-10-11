package com.editsathi.edit_sathi

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.editsathi.edit_sathi/thumbnail"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getVideoThumbnail") {
                val videoPath = call.argument<String>("videoPath")
                val timeMs = call.argument<Int>("timeMs") ?: 500
                val quality = call.argument<Int>("quality") ?: 85

                if (videoPath == null) {
                    result.error("INVALID_PATH", "Video path cannot be null", null)
                    return@setMethodCallHandler
                }

                Thread {
                    val retriever = MediaMetadataRetriever()
                    try {
                        val file = File(videoPath)
                        if (file.exists()) {
                            retriever.setDataSource(file.absolutePath)
                        } else {
                            retriever.setDataSource(videoPath)
                        }

                        val timeUs = timeMs * 1000L
                        val bitmap: Bitmap? = retriever.getFrameAtTime(
                            timeUs,
                            MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                        ) ?: retriever.frameAtTime

                        if (bitmap != null) {
                            val thumbDir = File(cacheDir, "thumbnails")
                            if (!thumbDir.exists()) thumbDir.mkdirs()

                            val outFile = File(thumbDir, "thumb_${UUID.randomUUID().toString().substring(0, 8)}.jpg")
                            val outStream = FileOutputStream(outFile)
                            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outStream)
                            outStream.flush()
                            outStream.close()
                            bitmap.recycle()

                            runOnUiThread {
                                result.success(outFile.absolutePath)
                            }
                        } else {
                            runOnUiThread {
                                result.error("FRAME_EXTRACTION_FAILED", "Could not extract frame", null)
                            }
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("THUMBNAIL_ERROR", e.localizedMessage, null)
                        }
                    } finally {
                        try {
                            retriever.release()
                        } catch (_: Exception) {}
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }
}

package de.openshelf.app

import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // Tesseract is not thread-safe and slow: one worker, off the UI thread.
    private val worker = Executors.newSingleThreadExecutor()
    private val ui = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.openshelf.app/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val imagePath = call.argument<String>("imagePath")
                val dataPath = call.argument<String>("dataPath")
                val language = call.argument<String>("language")
                if (imagePath == null || dataPath == null || language == null) {
                    result.error("args", "imagePath, dataPath and language are required", null)
                    return@setMethodCallHandler
                }
                worker.execute {
                    val tess = TessBaseAPI()
                    try {
                        if (!tess.init(dataPath, language)) {
                            ui.post { result.error("init", "Tesseract could not load $language", null) }
                            return@execute
                        }
                        tess.setImage(File(imagePath))
                        val text = tess.utF8Text ?: ""
                        ui.post { result.success(text) }
                    } catch (e: Throwable) {
                        ui.post { result.error("ocr", e.message ?: e.javaClass.simpleName, null) }
                    } finally {
                        tess.recycle()
                    }
                }
            }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}

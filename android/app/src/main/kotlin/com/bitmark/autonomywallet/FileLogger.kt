package com.bitmark.autonomy_flutter

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream

class FileLogger(context: Context) {

    companion object {
        private var INSTANCE: FileLogger? = null

        fun init(context: Context) = INSTANCE ?: FileLogger(context).also { INSTANCE = it }

        fun log(tag: String, message: String) {
            INSTANCE?.log(tag, message)
        }
    }

    private val _fileLogger: File

    fun getFile(): File {
        return _fileLogger
    }

    init {
        _fileLogger = File(context.cacheDir, "app.log")
        if (!_fileLogger.exists()) {
            _fileLogger.createNewFile()
        }
    }

    private fun log(tag: String, message: String) {
        if (_fileLogger.canWrite()) {
            Log.d(tag, message)
            FileOutputStream(_fileLogger, true).apply {
                write("$tag: $message\n".encodeToByteArray())
                flush()
                close()
            }
        }
    }
}
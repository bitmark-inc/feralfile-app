package com.bitmark.autonomy_flutter

import android.content.Context
import timber.log.Timber
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.FileReader
import java.io.FileWriter

class FileLogger(context: Context) {

    companion object {
        private var INSTANCE: FileLogger? = null
        private const val MAX_LINES_TO_KEEP = 1000 // Số dòng log tối đa cần giữ lại

        fun init(context: Context) = INSTANCE ?: FileLogger(context).also { INSTANCE = it }

        fun log(tag: String, message: String) {
            INSTANCE?.log(tag, message)
        }

        fun getLogContent(): String {
            return INSTANCE?.readLogContent() ?: ""
        }
    }

    private val _fileLogger: File

    fun getFile(): File {
        return _fileLogger
    }

    init {
        _fileLogger = File(context.filesDir, "app.log")
        if (!_fileLogger.exists()) {
            _fileLogger.createNewFile()
        }
    }

    private fun readLogContent(): String {
        val content = StringBuilder()
        BufferedReader(FileReader(_fileLogger)).use { reader ->
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                content.append(line).append("\n")
            }
        }
        return content.toString()
    }

    private fun checkAndRotateLog() {
        val tempFile = File(_fileLogger.parent, "app.log.temp")
        val linesToKeep = ArrayDeque<String>(MAX_LINES_TO_KEEP)

        // Read the log file line by line and keep only the last MAX_LINES_TO_KEEP lines
        BufferedReader(FileReader(_fileLogger)).use { reader ->
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                if (linesToKeep.size == MAX_LINES_TO_KEEP) {
                    linesToKeep.removeFirst()
                }
                linesToKeep.addLast(line!!)
            }
        }

        // Write the retained lines to the temporary file
        FileWriter(tempFile).use { writer ->
            linesToKeep.forEach { writer.write("$it\n") }
        }

        // Replace the old log file with the new one
        if (_fileLogger.delete()) {
            tempFile.renameTo(_fileLogger)
        }
    }

    private fun log(tag: String, message: String) {
        if (_fileLogger.canWrite()) {
            checkAndRotateLog()

            val now =
                java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
                    .format(java.util.Date())
            Timber.tag(tag).d(message)
            FileOutputStream(_fileLogger, true).apply {
                write("[$now] $tag: $message\n".encodeToByteArray())
                flush()
                close()
            }
        }
    }
}
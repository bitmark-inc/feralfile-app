package com.bitmark.autonomy_flutter

import android.content.Context
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.io.BufferedReader
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
        
        // Đọc file log hiện tại và chỉ giữ lại MAX_LINES_TO_KEEP dòng cuối cùng
        val lines = mutableListOf<String>()
        BufferedReader(FileReader(_fileLogger)).use { reader ->
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                lines.add(line!!)
            }
        }
        
        // Nếu số dòng vượt quá giới hạn, thực hiện xoay vòng
        if (lines.size > MAX_LINES_TO_KEEP) {
            // Giữ lại MAX_LINES_TO_KEEP dòng cuối cùng
            val linesToKeep = lines.subList(lines.size - MAX_LINES_TO_KEEP, lines.size)
            
            // Thêm thông báo về việc xoay vòng log
            val now = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
                .format(java.util.Date())
            linesToKeep.add(0, "[$now] FileLogger: Log file rotated. Kept last $MAX_LINES_TO_KEEP lines.")
            
            // Ghi các dòng đã chọn vào file tạm
            FileWriter(tempFile).use { writer ->
                linesToKeep.forEach { line ->
                    writer.write("$line\n")
                }
            }
            
            // Xóa file log cũ và đổi tên file tạm thành file log mới
            _fileLogger.delete()
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
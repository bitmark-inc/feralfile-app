package com.bitmark.autonomywallet

import android.content.Context
import java.io.File

class FileStorageHelper(private val context: Context) {

    fun listFiles(): List<String> {
        val filesDir = context.filesDir
        return filesDir.list()?.toList() ?: emptyList()
    }

    fun readOnFilesDir(fileName: String): ByteArray {
        val file = File(context.filesDir, fileName)
        return file.readBytes()
    }
} 
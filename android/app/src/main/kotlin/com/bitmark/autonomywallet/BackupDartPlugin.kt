/* SPDX-License-Identifier: BSD-2-Clause-Patent
 * Copyright © 2022 Bitmark. All rights reserved.
 * Use of this source code is governed by the BSD-2-Clause Plus Patent License
 * that can be found in the LICENSE file.
 */

package com.bitmark.autonomy_flutter

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.bitmark.libauk.LibAuk
import com.google.android.gms.auth.blockstore.*
import com.google.android.gms.auth.blockstore.BlockstoreClient.DEFAULT_BYTES_DATA_KEY
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.reactivex.Completable
import io.reactivex.Observable
import io.reactivex.Single
import io.reactivex.disposables.CompositeDisposable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.*

class BackupDartPlugin : MethodChannel.MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var disposables: CompositeDisposable
    private lateinit var client: BlockstoreClient
    private val primaryAddressStoreKey = "primary_address"
    private val jwtStoreKey = "jwt"
    private val didRegisterPasskeys = "did_register_passkeys"

    fun createChannels(@NonNull flutterEngine: FlutterEngine, @NonNull context: Context) {
        this.context = context
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "backup")
        channel.setMethodCallHandler(this)
        disposables = CompositeDisposable()
        client = Blockstore.getClient(context)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "isEndToEndEncryptionAvailable" -> isEndToEndEncryptionAvailable(result)
            "restoreKeys" -> restoreKeys(call, result)
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isEndToEndEncryptionAvailable(result: MethodChannel.Result) {
        client.isEndToEndEncryptionAvailable
            .addOnSuccessListener { isE2EEAvailable ->
                result.success(isE2EEAvailable)
            }
            .addOnFailureListener {
                //Block store not available
                result.success(null)
            }
    }

    private fun restoreKeys(call: MethodCall, result: MethodChannel.Result) {
        val retrieveBytesRequestBuilder = RetrieveBytesRequest.Builder()
            .setRetrieveAll(true)
        
        client.retrieveBytes(retrieveBytesRequestBuilder.build())
            .addOnSuccessListener { bytes ->
                try {
                    val dataMap = bytes.blockstoreDataMap
                    val defaultBytesData = dataMap[DEFAULT_BYTES_DATA_KEY]
                    val data = jsonKT.decodeFromString(
                        BackupData.serializer(),
                        defaultBytesData?.bytes?.toString(Charsets.UTF_8) ?: ""
                    )

                    val mnemonics = data.accounts.map { it.mnemonic }
                    result.success(mnemonics)
                    
                } catch (e: Exception) {
                    // No accounts found
                    result.success(emptyList<String>())
                }
            }
            .addOnFailureListener { e ->
                Log.e("RestoreDartPlugin", e.message ?: "Blockstore retrieval error")
                result.error("restorePrimaryAddress error", e.message, e)
            }
    }
}

@Serializable
data class BackupData(
    @SerialName("accounts")
    val accounts: List<BackupAccount>
)

@Serializable
data class BackupAccount(
    @SerialName("uuid")
    val uuid: String,
    @SerialName("mnemonic")
    val mnemonic: String,
    @SerialName("passphrase")
    val passphrase: String?,
    @SerialName("name")
    val name: String,
)
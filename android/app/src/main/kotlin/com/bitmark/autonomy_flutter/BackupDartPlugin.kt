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
            "backupKeys" -> backupKeys(call, result)
            "restoreKeys" -> restoreKeys(call, result)
            "setPrimaryAddress" -> setPrimaryAddress(call, result)
            "getPrimaryAddress" -> getPrimaryAddress(call, result)
            "clearPrimaryAddress" -> clearPrimaryAddress(call, result)
            "deleteKeys" -> deleteKeys(call, result)
            "setDidRegisterPasskey" -> setDidRegisterPasskey(call, result)
            "didRegisterPasskey" -> didRegisterPasskey(call, result)
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

    private fun backupKeys(call: MethodCall, result: MethodChannel.Result) {
        val uuids: List<String> = call.argument("uuids") ?: return

        Observable
            .fromIterable(uuids)
            .flatMap {
                Single.zip(
                    LibAuk.getInstance().getStorage(UUID.fromString(it), context)
                        .exportMnemonicWords(),
                    LibAuk.getInstance().getStorage(UUID.fromString(it), context)
                        .exportMnemonicPassphrase(),
                    LibAuk.getInstance().getStorage(UUID.fromString(it), context).getName()
                ) { mnemonic, passphrase, name ->
                    BackupAccount(it, mnemonic, passphrase, name)
                }.toObservable()
            }
            .toList()
            .subscribe({ keys ->
                val data = BackupData(keys)
                val backupJson = jsonKT.encodeToString(BackupData.serializer(), data)
                val storeBytesDataBuilder = StoreBytesData.Builder()
                    .setBytes(backupJson.toByteArray(Charsets.UTF_8))

                client.isEndToEndEncryptionAvailable
                    .addOnSuccessListener { isE2EEAvailable ->
                        if (isE2EEAvailable) {
                            storeBytesDataBuilder.setShouldBackupToCloud(true)
                        }
                        client.storeBytes(storeBytesDataBuilder.build())
                            .addOnSuccessListener {
                                result.success("")
                            }
                            .addOnFailureListener { e ->
                                Log.e("BackupDartPlugin", e.message ?: "")
                                result.error("backupKeys error", e.message, e)
                            }
                    }
                    .addOnFailureListener {
                        //Block store not available
                        Log.e("BackupDartPlugin", it.message ?: "")
                        result.error("backupKeys error", it.message, it)
                    }
            }, {
                Log.e("BackupDartPlugin", it.message ?: "")
                result.error("backupKeys error", it.message, it)
            })
            .let { disposables.add(it) }

    }

    private fun restoreKeys(call: MethodCall, result: MethodChannel.Result) {
        val retrieveBytesRequestBuilder = RetrieveBytesRequest.Builder()
            .setRetrieveAll(true)
        client.retrieveBytes(retrieveBytesRequestBuilder.build())
            .addOnSuccessListener { bytes ->
                try {
                    val dataMap = bytes.blockstoreDataMap;
                    val defaultBytesData = dataMap[DEFAULT_BYTES_DATA_KEY];
                    val data = jsonKT.decodeFromString(
                        BackupData.serializer(),
                        defaultBytesData?.bytes?.toString(Charsets.UTF_8) ?: ""
                    )

                    Observable.fromIterable(data.accounts)
                        .flatMap { account ->
                            LibAuk.getInstance()
                                .getStorage(UUID.fromString(account.uuid), context)
                                .isWalletCreated()
                                .flatMapCompletable { isCreated ->
                                    if (!isCreated) {
                                        LibAuk.getInstance()
                                            .getStorage(UUID.fromString(account.uuid), context)
                                            .importKey(
                                                account.mnemonic.split(" "),
                                                account.passphrase ?: "",
                                                account.name,
                                                Date()
                                            )
                                    } else {
                                        Completable.complete()
                                    }
                                }
                                .andThen(
                                    Observable.just(
                                        BackupAccount(
                                            account.uuid,
                                            "",
                                            account.passphrase ?: "",
                                            account.name
                                        )
                                    )
                                )
                        }
                        .toList()
                        .subscribe({
                            val resultData =
                                jsonKT.encodeToString(BackupData.serializer(), BackupData(it))
                            result.success(resultData)
                        }, {
                            result.error("restoreKey error", it.message, it)
                        })
                        .let { disposables.add(it) }
                } catch (e: Exception) {
                    //No accounts found
                    result.success("")
                }
            }
            .addOnFailureListener { e ->
                // Block store not available or error occurred during retrieval
                Log.e("RestoreDartPlugin", e.message ?: "Blockstore retrieval error")
                result.error("restorePrimaryAddress error", e.message, e)
            }
    }

    private fun setPrimaryAddress(call: MethodCall, result: MethodChannel.Result) {
        val data: String = call.argument("data") ?: return

        val storeBytesBuilder = StoreBytesData.Builder()
            .setKey(primaryAddressStoreKey)
            .setBytes(data.toByteArray(Charsets.UTF_8))


        Log.e("setPrimaryAddress", "Primary address setting");

        client.isEndToEndEncryptionAvailable
            .addOnSuccessListener { isE2EEAvailable ->
                if (isE2EEAvailable) {
                    storeBytesBuilder.setShouldBackupToCloud(true)
                }
                client.storeBytes(storeBytesBuilder.build())
                    .addOnSuccessListener {

                        Log.e("setPrimaryAddress", "Primary address set successfully");
                        result.success("")
                    }
                    .addOnFailureListener { e ->
                        Log.e("setPrimaryAddress", e.message ?: "")
                        result.error("setPrimaryAddress error", e.message, e)
                    }
            }
            .addOnFailureListener {
                // Block store not available
                Log.e("setPrimaryAddress", it.message ?: "")
                result.error("setPrimaryAddress error", it.message, it)
            }
    }

    private fun getPrimaryAddress(call: MethodCall, result: MethodChannel.Result) {
        val request = RetrieveBytesRequest.Builder()
            .setKeys(listOf(primaryAddressStoreKey))  // Specify the key
            .build()
        client.retrieveBytes(request)
            .addOnSuccessListener {
                try { // Retrieve bytes using the key
                    val dataMap = it.blockstoreDataMap[primaryAddressStoreKey]
                    if (dataMap != null) {
                        val bytes = dataMap.bytes
                        val jsonString = bytes.toString(Charsets.UTF_8)
                        Log.d("getPrimaryAddress", "Retrieved JSON: $jsonString")


                        result.success(jsonString)
                    } else {
                        Log.e("getPrimaryAddress", "No data found for the key")
                        result.success(null)
                    }
                } catch (e: Exception) {
                    Log.e("getPrimaryAddress", e.message ?: "Error decoding data")
                    //No primary address found
                    result.success("")
                }
            }
            .addOnFailureListener {
                //Block store not available
                result.error("getPrimaryAddress Block store error", it.message, it)
            }
    }

    private fun setDidRegisterPasskey(call: MethodCall, result: MethodChannel.Result) {
        val data: Boolean = call.argument("data") ?: false

        val storeBytesBuilder = StoreBytesData.Builder()
            .setKey(didRegisterPasskeys)
            .setBytes(data.toString().toByteArray(Charsets.UTF_8))

        client.storeBytes(storeBytesBuilder.build())
            .addOnSuccessListener {

                Log.e("setDidRegisterPasskey", data.toString());
                result.success(true)
            }
            .addOnFailureListener { e ->
                Log.e("setDidRegisterPasskey", e.message ?: "")
                result.success(false)
            }
    }

    private fun didRegisterPasskey(call: MethodCall, result: MethodChannel.Result) {
        val request = RetrieveBytesRequest.Builder()
            .setKeys(listOf(didRegisterPasskeys))  // Specify the key
            .build()
        client.retrieveBytes(request)
            .addOnSuccessListener {
                try { // Retrieve bytes using the key
                    val dataMap = it.blockstoreDataMap[didRegisterPasskeys]
                    if (dataMap != null) {
                        val bytes = dataMap.bytes
                        val resultString = bytes.toString(Charsets.UTF_8)
                        Log.d("didRegisterPasskey", resultString)


                        result.success(resultString.toBoolean())
                    } else {
                        Log.e("didRegisterPasskey", "No data found for the key")
                        result.success(false)
                    }
                } catch (e: Exception) {
                    Log.e("didRegisterPasskey", e.message ?: "Error decoding data")
                    //No primary address found
                    result.success(false)
                }
            }
            .addOnFailureListener {
                //Block store not available
                result.error("didRegisterPasskey Block store error", it.message, it)
            }
    }


    private fun clearPrimaryAddress(call: MethodCall, result: MethodChannel.Result) {
        val retrieveRequest = DeleteBytesRequest.Builder()
            .setKeys(listOf(primaryAddressStoreKey))
            .build()
        client.deleteBytes(retrieveRequest)
            .addOnSuccessListener {
                result.success(it)
            }
            .addOnFailureListener {
                result.error("deletePrimaryAddress error", it.message, it)
            }
    }

    private fun deleteKeys(call: MethodCall, result: MethodChannel.Result) {
        val deleteRequestBuilder = DeleteBytesRequest.Builder()
            .setDeleteAll(true)
        client.deleteBytes(deleteRequestBuilder.build())
            .addOnSuccessListener {
                result.success("")
            }
            .addOnFailureListener { e ->
                Log.e("BackupDartPlugin", e.message ?: "")
                result.error("deleteKeys error", e.message, e)
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
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
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.reactivex.Completable
import io.reactivex.Observable
import io.reactivex.Single
import io.reactivex.disposables.CompositeDisposable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
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
    private final val primaryAddressStoreKey = "primary_address"

    // Initialize a JSON serializer instance
    private val jsonKT = Json { ignoreUnknownKeys = true }

    fun createChannels(@NonNull flutterEngine: FlutterEngine, @NonNull context: Context) {
        this.context = context
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "backup")
        channel.setMethodCallHandler(this)
        disposables = CompositeDisposable()
        client = Blockstore.getClient(context)
        Log.d("BackupDartPlugin", "MethodChannel 'backup' initialized.")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Method called: ${call.method}")
        when (call.method) {
            "isEndToEndEncryptionAvailable" -> isEndToEndEncryptionAvailable(result)
            "backupKeys" -> backupKeys(call, result)
            "restoreKeys" -> restoreKeys(call, result)
            "setPrimaryAddress" -> setPrimaryAddress(call, result)
            "getPrimaryAddress" -> getPrimaryAddress(call, result)
            "clearPrimaryAddress" -> clearPrimaryAddress(call, result)
            "deleteKeys" -> deleteKeys(call, result)
            else -> {
                Log.w("BackupDartPlugin", "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun isEndToEndEncryptionAvailable(result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Checking if End-to-End Encryption is available.")
        client.isEndToEndEncryptionAvailable
            .addOnSuccessListener(OnSuccessListener<Boolean> { isE2EEAvailable ->
                Log.d("BackupDartPlugin", "E2EE Available: $isE2EEAvailable")
                result.success(isE2EEAvailable)
            })
            .addOnFailureListener(OnFailureListener { e ->
                Log.e("BackupDartPlugin", "Failed to check E2EE availability: ${e.message}", e)
                //Block store not available
                result.success(null)
            })
    }

    private fun backupKeys(call: MethodCall, result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Starting backupKeys operation.")
        val uuids: List<String>? = call.argument("uuids")
        if (uuids == null) {
            Log.e("BackupDartPlugin", "backupKeys error: 'uuids' argument is null.")
            result.error("backupKeys error", "'uuids' argument is null.", null)
            return
        }

        Log.d("BackupDartPlugin", "Number of UUIDs to backup: ${uuids.size}")

        Observable.fromIterable(uuids)
            .flatMap { uuidStr ->
                try {
                    Log.d("BackupDartPlugin", "Processing UUID: $uuidStr")
                    val uuid = UUID.fromString(uuidStr)
                    val storage = LibAuk.getInstance().getStorage(uuid, context)
                    Log.d("BackupDartPlugin", "Retrieved storage for UUID: $uuidStr")
                    Single.zip(
                        storage.exportMnemonicWords(),
                        storage.exportMnemonicPassphrase(),
                        storage.getName(),
                        { mnemonic, passphrase, name ->
                            Log.d("BackupDartPlugin", "Exported data for UUID: $uuidStr")
                            BackupAccount(uuidStr, mnemonic, passphrase, name)
                        }
                    ).toObservable()
                } catch (e: IllegalArgumentException) {
                    Log.e("BackupDartPlugin", "Invalid UUID format: $uuidStr", e)
                    // Emit an error to be caught in subscribe's onError
                    Single.error<BackupAccount>(e).toObservable()
                }
            }
            .toList()
            .subscribe({ keys ->
                Log.d("BackupDartPlugin", "Successfully backed up ${keys.size} keys.")
                try {
                    val data = BackupData(keys)
                    val backupJson = jsonKT.encodeToString(BackupData.serializer(), data)
                    Log.d("BackupDartPlugin", "Serialized backup data to JSON. Size: ${backupJson.length} characters.")

                    val storeBytesDataBuilder = StoreBytesData.Builder()
                        .setBytes(backupJson.toByteArray(Charsets.UTF_8))
                    Log.d("BackupDartPlugin", "Prepared StoreBytesData for backup.")

                    client.isEndToEndEncryptionAvailable
                        .addOnSuccessListener { isE2EEAvailable ->
                            Log.d("BackupDartPlugin", "E2EE Available: $isE2EEAvailable")
                            if (isE2EEAvailable) {
                                storeBytesDataBuilder.setShouldBackupToCloud(true)
                                Log.d("BackupDartPlugin", "Configured to backup to cloud.")
                            }
                            client.storeBytes(storeBytesDataBuilder.build())
                                .addOnSuccessListener {
                                    Log.d("BackupDartPlugin", "Backup stored successfully.")
                                    result.success("Backup successful")
                                }
                                .addOnFailureListener { e ->
                                    Log.e("BackupDartPlugin", "Failed to store backup: ${e.message}", e)
                                    result.error("backupKeys error", "Failed to store backup: ${e.localizedMessage}", e)
                                }
                        }
                        .addOnFailureListener { e ->
                            Log.e("BackupDartPlugin", "Failed to check E2EE availability: ${e.message}", e)
                            //Block store not available
                            result.error("backupKeys error", "E2EE availability check failed: ${e.localizedMessage}", e)
                        }
                } catch (e: Exception) {
                    Log.e("BackupDartPlugin", "Exception during backupKeys serialization: ${e.message}", e)
                    result.error("backupKeys error", "Serialization failed: ${e.localizedMessage}", e)
                }
            }, { error ->
                Log.e("BackupDartPlugin", "Error during backupKeys: ${error.message}", error)
                result.error("backupKeys error", "Error during backupKeys: ${error.localizedMessage}", error)
            })
            .let { disposables.add(it) }
    }

    private fun restoreKeys(call: MethodCall, result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Starting restoreKeys operation.")
        val retrieveBytesRequestBuilder = RetrieveBytesRequest.Builder()
            .setRetrieveAll(true)
        client.retrieveBytes(retrieveBytesRequestBuilder.build())
            .addOnSuccessListener { bytes ->
                Log.d("BackupDartPlugin", "Successfully retrieved bytes from Blockstore.")
                try {
                    val dataMap = bytes.blockstoreDataMap
                    Log.d("BackupDartPlugin", "Retrieved blockstoreDataMap with ${dataMap.size} entries.")

                    val defaultBytesData = dataMap[DEFAULT_BYTES_DATA_KEY]
                    if (defaultBytesData == null) {
                        Log.w("BackupDartPlugin", "No data found for DEFAULT_BYTES_DATA_KEY.")
                        result.success("")
                        return@addOnSuccessListener
                    }

                    val backupJson = defaultBytesData.bytes.toString(Charsets.UTF_8)
                    Log.d("BackupDartPlugin", "Deserialized backup JSON. Size: ${backupJson.length} characters.")

                    val data = jsonKT.decodeFromString(BackupData.serializer(), backupJson)
                    Log.d("BackupDartPlugin", "Parsed BackupData with ${data.accounts.size} accounts.")

                    Observable.fromIterable(data.accounts)
                        .flatMap { account ->
                            Log.d("BackupDartPlugin", "Processing account UUID: ${account.uuid}")
                            LibAuk.getInstance()
                                .getStorage(UUID.fromString(account.uuid), context)
                                .isWalletCreated()
                                .flatMapCompletable { isCreated ->
                                    if (!isCreated) {
                                        Log.d("BackupDartPlugin", "Wallet not created for UUID: ${account.uuid}. Importing key.")
                                        LibAuk.getInstance()
                                            .getStorage(UUID.fromString(account.uuid), context)
                                            .importKey(
                                                account.mnemonic.split(" "),
                                                account.passphrase ?: "",
                                                account.name,
                                                Date()
                                            )
                                            .doOnComplete {
                                                Log.d("BackupDartPlugin", "Imported key for UUID: ${account.uuid}")
                                            }
                                            .doOnError { e ->
                                                Log.e("BackupDartPlugin", "Failed to import key for UUID: ${account.uuid}: ${e.message}", e)
                                            }
                                    } else {
                                        Log.d("BackupDartPlugin", "Wallet already created for UUID: ${account.uuid}. Skipping import.")
                                        Completable.complete()
                                    }
                                }
                                .andThen(
                                    Observable.just(
                                        BackupAccount(
                                            account.uuid,
                                            "", // Clear mnemonic as it's sensitive
                                            account.passphrase ?: "",
                                            account.name
                                        )
                                    )
                                )
                        }
                        .toList()
                        .subscribe({ restoredAccounts ->
                            Log.d("BackupDartPlugin", "Successfully restored ${restoredAccounts.size} accounts.")
                            val resultData = jsonKT.encodeToString(BackupData.serializer(), BackupData(restoredAccounts))
                            Log.d("BackupDartPlugin", "Serialized restored data to JSON. Size: ${resultData.length} characters.")
                            result.success(resultData)
                        }, { error ->
                            Log.e("BackupDartPlugin", "Error during restoreKeys: ${error.message}", error)
                            result.error("restoreKeys error", "Error during restoreKeys: ${error.localizedMessage}", error)
                        })
                        .let { disposables.add(it) }
                } catch (e: Exception) {
                    Log.e("BackupDartPlugin", "Exception during restoreKeys: ${e.message}", e)
                    //No accounts found or deserialization failed
                    result.success("")
                }
            }
            .addOnFailureListener { e ->
                Log.e("BackupDartPlugin", "Failed to retrieve bytes from Blockstore: ${e.message}", e)
                // Block store not available or error occurred during retrieval
                result.error("restoreKeys error", "Blockstore retrieval error: ${e.localizedMessage}", e)
            }
    }

    private fun setPrimaryAddress(call: MethodCall, result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Starting setPrimaryAddress operation.")
        val data: String? = call.argument("data")
        if (data == null) {
            Log.e("BackupDartPlugin", "setPrimaryAddress error: 'data' argument is null.")
            result.error("setPrimaryAddress error", "'data' argument is null.", null)
            return
        }

        val storeBytesBuilder = StoreBytesData.Builder()
            .setKey(primaryAddressStoreKey)
            .setBytes(data.toByteArray(Charsets.UTF_8))
        Log.d("BackupDartPlugin", "Prepared StoreBytesData for primary address. Data size: ${data.length} characters.")

        client.isEndToEndEncryptionAvailable
            .addOnSuccessListener { isE2EEAvailable ->
                Log.d("BackupDartPlugin", "E2EE Available: $isE2EEAvailable")
                if (isE2EEAvailable) {
                    storeBytesBuilder.setShouldBackupToCloud(true)
                    Log.d("BackupDartPlugin", "Configured to backup primary address to cloud.")
                }
                client.storeBytes(storeBytesBuilder.build())
                    .addOnSuccessListener {
                        Log.d("BackupDartPlugin", "Primary address set successfully.")
                        result.success("Primary address set successfully.")
                    }
                    .addOnFailureListener { e ->
                        Log.e("BackupDartPlugin", "Failed to set primary address: ${e.message}", e)
                        result.error("setPrimaryAddress error", "Failed to set primary address: ${e.localizedMessage}", e)
                    }
            }
            .addOnFailureListener { e ->
                Log.e("BackupDartPlugin", "Failed to check E2EE availability: ${e.message}", e)
                // Block store not available
                result.error("setPrimaryAddress error", "E2EE availability check failed: ${e.localizedMessage}", e)
            }
    }

    private fun getPrimaryAddress(call: MethodCall, result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Starting getPrimaryAddress operation.")
        val request = RetrieveBytesRequest.Builder()
            .setKeys(listOf(primaryAddressStoreKey))  // Specify the key
            .build()
        client.retrieveBytes(request)
            .addOnSuccessListener { bytes ->
                Log.d("BackupDartPlugin", "Successfully retrieved bytes for primary address.")
                try { // Retrieve bytes using the key
                    val dataMap = bytes.blockstoreDataMap[primaryAddressStoreKey]
                    if (dataMap != null) {
                        val bytesData = dataMap.bytes
                        Log.d("BackupDartPlugin", "Retrieved bytes data for primary address. Size: ${bytesData.size} bytes.")
                        val jsonString = bytesData.toString(Charsets.UTF_8)
                        Log.d("BackupDartPlugin", "Deserialized primary address JSON. Content length: ${jsonString.length} characters.")
                        result.success(jsonString)
                    } else {
                        Log.w("BackupDartPlugin", "No data found for primaryAddressStoreKey.")
                        result.success(null)
                    }
                } catch (e: Exception) {
                    Log.e("BackupDartPlugin", "Exception during getPrimaryAddress: ${e.message}", e)
                    //No primary address found or deserialization failed
                    result.success("")
                }
            }
            .addOnFailureListener { e ->
                Log.e("BackupDartPlugin", "Failed to retrieve primary address from Blockstore: ${e.message}", e)
                //Block store not available
                result.error("getPrimaryAddress error", "Blockstore retrieval error: ${e.localizedMessage}", e)
            }
    }

    private fun clearPrimaryAddress(call: MethodCall, result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Starting clearPrimaryAddress operation.")
        val retrieveRequest = DeleteBytesRequest.Builder()
            .setKeys(listOf(primaryAddressStoreKey))
            .build()
        client.deleteBytes(retrieveRequest)
            .addOnSuccessListener {
                Log.d("BackupDartPlugin", "Primary address cleared successfully.")
                result.success("Primary address cleared successfully.")
            }
            .addOnFailureListener { e ->
                Log.e("BackupDartPlugin", "Failed to clear primary address: ${e.message}", e)
                result.error("deletePrimaryAddress error", "Failed to clear primary address: ${e.localizedMessage}", e)
            }
    }

    private fun deleteKeys(call: MethodCall, result: MethodChannel.Result) {
        Log.d("BackupDartPlugin", "Starting deleteKeys operation.")
        val deleteRequestBuilder = DeleteBytesRequest.Builder()
            .setDeleteAll(true)
        client.deleteBytes(deleteRequestBuilder.build())
            .addOnSuccessListener {
                Log.d("BackupDartPlugin", "All keys deleted successfully.")
                result.success("All keys deleted successfully.")
            }
            .addOnFailureListener { e ->
                Log.e("BackupDartPlugin", "Failed to delete keys: ${e.message}", e)
                result.error("deleteKeys error", "Failed to delete keys: ${e.localizedMessage}", e)
            }
    }

    // Ensure to dispose of the CompositeDisposable when no longer needed
    fun dispose() {
        if (::disposables.isInitialized) {
            disposables.dispose()
            Log.d("BackupDartPlugin", "CompositeDisposable disposed.")
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
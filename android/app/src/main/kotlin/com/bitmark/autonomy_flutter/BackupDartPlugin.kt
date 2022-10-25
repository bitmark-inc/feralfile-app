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
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.BlockstoreClient
import com.google.android.gms.auth.blockstore.StoreBytesData
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
                    LibAuk.getInstance().getStorage(UUID.fromString(it), context).getName()
                ) { mnemonic, name ->
                    BackupAccount(it, mnemonic, name)
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
        client.retrieveBytes()
            .addOnSuccessListener { bytes ->
                try {
                    val data = jsonKT.decodeFromString(
                        BackupData.serializer(),
                        bytes.toString(Charsets.UTF_8)
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
            .addOnFailureListener {
                //Block store not available
                result.error("restoreKey error", it.message, it)
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
    @SerialName("name")
    val name: String,
)
package com.bitmark.autonomy_flutter

import android.content.Context
import com.bitmark.libauk.LibAuk
import com.bitmark.libauk.storage.ETH_KEY_INFO_FILE_NAME
import com.bitmark.libauk.util.newGsonInstance
import io.reactivex.Single
import java.util.UUID

class LibAukUtil {
    companion object {

        fun migrate(context: Context) {
            migrateV1(context).subscribe()
        }

        private fun readAllKeyStoreFiles(
            nameFilterFunction: (String) -> Boolean,
            context: Context
        ): Single<Map<String, ByteArray>> {
            return Single.fromCallable {
                val files = context.filesDir.listFiles { _, name -> nameFilterFunction(name) }
                val map = mutableMapOf<String, ByteArray>()
                files?.forEach { file ->
                    val name = file.name.substringAfter("-")
                    val data = file.readBytes()
                    map[name] = data
                }
                map
            }
        }

        private fun migrateV1(context: Context): Single<Unit> {
            return readAllKeyStoreFiles(
                { name -> name.endsWith(ETH_KEY_INFO_FILE_NAME) },
                context
            ).map { filesMap ->
                filesMap.forEach { (name, data) ->
                    val uuid = name.substringBefore("-")
                    val storage = LibAuk.getInstance().getStorage(UUID.fromString(uuid), context)
                    storage.exportSeed(withAuthentication = false).map { seed ->
                        val seedPublicData = storage.generateSeedPublicData(seed)
                        storage.writeOnFilesDir(
                            "libauk_seed_public_data.dat",
                            newGsonInstance().toJson(seedPublicData).toByteArray(),
                            false
                        )
                    }
                    storage.removeKey(ETH_KEY_INFO_FILE_NAME)
                }
            }
        }
    }
}
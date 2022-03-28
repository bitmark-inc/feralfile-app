package com.bitmark.autonomy_flutter

import TezosBeaconDartPlugin
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "migration_util"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getExistingUuids") {
                val uuids = getExistingUuids()
                result.success(uuids)
            } else {
                result.notImplemented()
            }
        }

        BackupDartPlugin().createChannels(flutterEngine, applicationContext)
        TezosBeaconDartPlugin().createChannels(flutterEngine)
    }

    private fun getExistingUuids(): String {
        val sharedPreferences = this.getSharedPreferences(
            BuildConfig.APPLICATION_ID, Context.MODE_PRIVATE
        )
        return sharedPreferences.getString("persona_uuids", "") ?: ""
    }

}
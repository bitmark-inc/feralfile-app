/* SPDX-License-Identifier: BSD-2-Clause-Patent
 * Copyright © 2022 Bitmark. All rights reserved.
 * Use of this source code is governed by the BSD-2-Clause Plus Patent License
 * that can be found in the LICENSE file.
 */

package com.bitmark.autonomy_flutter

import TezosBeaconDartPlugin
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        var isAuthenticate: Boolean = false
        private const val CHANNEL = "migration_util"
    }

    var flutterSharedPreferences: SharedPreferences? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FileLogger.init(applicationContext)
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

    override fun onResume() {
        super.onResume()

        val sharedPreferences = flutterSharedPreferences ?: this.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        val isEnabled = sharedPreferences.getBoolean("flutter.device_passcode", false)
        if (isEnabled && !isAuthenticate) {
            val biometricManager = BiometricManager.from(this)
            val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
            if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                == BiometricManager.BIOMETRIC_SUCCESS || keyguardManager.isDeviceSecure
            ) {
                val intent = Intent(this@MainActivity, AuthenticatorActivity::class.java)
                startActivity(intent)
            }
        }
    }

    override fun onPause() {
        super.onPause()
        isAuthenticate = false
    }
}
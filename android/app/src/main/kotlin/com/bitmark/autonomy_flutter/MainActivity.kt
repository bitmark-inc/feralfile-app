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
import android.os.Build
import android.view.WindowManager.LayoutParams
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.scottyab.rootbeer.RootBeer

class MainActivity : FlutterFragmentActivity() {
    companion object {
        var isAuthenticate: Boolean = false
        private const val CHANNEL = "migration_util"
        private val secureScreenChannel = "secure_screen_channel"
    }

    var flutterSharedPreferences: SharedPreferences? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FileLogger.init(applicationContext)
        // Create a RootBeer instance
        val rootBeer = RootBeer(this)
        if (rootBeer.isRooted) {
            Toast.makeText(this, "This app cannot be used on rooted devices.", Toast.LENGTH_SHORT)
                .show()
            finish() // Close the app
        }
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureScreenChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "setSecureFlag") {
                val secure = call.argument<Boolean>("secure") ?: false
                setSecureFlag(secure)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.setHideOverlayWindows(true)
        }
    }

    private fun getExistingUuids(): String {
        val sharedPreferences = this.getSharedPreferences(
            BuildConfig.APPLICATION_ID, Context.MODE_PRIVATE
        )
        return sharedPreferences.getString("persona_uuids", "") ?: ""
    }

    private fun setSecureFlag(secure: Boolean) {
        if (secure) {
            window.addFlags(LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(LayoutParams.FLAG_SECURE)
        }
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
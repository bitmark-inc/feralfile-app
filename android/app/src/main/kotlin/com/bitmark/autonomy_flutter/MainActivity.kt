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
import android.os.Bundle
import android.util.Log
import android.view.View.ACCESSIBILITY_DATA_SENSITIVE_YES
import android.view.WindowManager.LayoutParams
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity : FlutterFragmentActivity() {
    companion object {
        var isAuthenticate: Boolean = false
        private const val CHANNEL = "migration_util"
        private val secureScreenChannel = "secure_screen_channel"
        private var lastAuthTime: Long = 0
        private val authenticationTimeout = TimeUnit.MINUTES.toMillis(3)
        private var isThisFirstOnResume = true;
    }

    var flutterSharedPreferences: SharedPreferences? = null

    private fun settingFlutterView() {
        val flutterView = FlutterView(this)
        if (Build.VERSION.SDK_INT >= 34) {
            flutterView.setAccessibilityDataSensitive(ACCESSIBILITY_DATA_SENSITIVE_YES)
        }
    }

    //DONT REMOVE; We will bring back this code when we need to verify the signature
    // check if the signature is valid
//    private fun isSignatureValid(
//        context: Context,
//        expectedSignatureHash: String
//    ): Boolean {
//        try {
//            val packageInfo = context.packageManager.getPackageInfo(
//                context.packageName,
//                PackageManager.GET_SIGNING_CERTIFICATES
//            )
//            val signatures = packageInfo.signingInfo.apkContentsSigners
//            val md = MessageDigest.getInstance("SHA-256")
//            for (signature in signatures) {
//                md.update(signature.toByteArray())
//                val currentSignatureHash = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
//                if (currentSignatureHash == expectedSignatureHash) {
//                    return true
//                }
//            }
//        } catch (e: Exception) {
//            Log.e("Signature", e.message.toString())
//        }
//        return false
//    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        settingFlutterView()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FileLogger.init(applicationContext)
        // verity signing certificate

        // DONT REMOVE, we will bring back this code when we need to verify the signature
//        checkSecurity()
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

    // DONT REMOVE, we will bring back this code when we need to verify the signature
    // detect frida
//    private fun detectFrida(): Boolean {
//        return detectFridaPort() || detectFridaMem()
//    }

    // DONT REMOVE, we will bring back this code when we need to verify the signature
    // check security
//    private fun checkSecurity() {
//        val handler = Handler(Looper.getMainLooper())
//
//        handler.postDelayed({
//            if (detectFrida()) {
//                captureMessage("[Security check] Reverse engineering tool detected")
//                finish()
//            }
//            val isSignatureValid = isSignatureValid(this, BuildConfig.SIGNATURE_HASH)
//            if (!isSignatureValid) {
//                captureMessage("[Security check] Invalid signature detected")
//                Toast.makeText(this, "Invalid signature", Toast.LENGTH_SHORT).show()
//                finish()
//            }
//
//            // Detect rooted devices
//            // Create a RootBeer instance
//            val rootBeer = RootBeer(this)
//            if (rootBeer.isRooted) {
//                captureMessage("[Security check] Rooted device detected")
//                Toast.makeText(this, "This app cannot be used on rooted devices.", Toast.LENGTH_SHORT)
//                    .show()
//                finish() // Close the app
//            }
//
//            // debugger detection
//            val hasTracerPid = hasTracerPid()
//            if (BuildConfig.ENABLE_DEBUGGER_DETECTION && hasTracerPid) {
//                captureMessage("[Security check] Debugger detected")
//                Toast.makeText(
//                    this,
//                    "Debugging detected. Please try again without any debugging tools.",
//                    Toast.LENGTH_SHORT
//                )
//                    .show()
//                finish()
//            }
//        }, 5000L)
//    }

    // DONT REMOVE, we will bring back this code when we need to verify the signature
//    private fun captureMessage(message: String) {
//        try {
//            Sentry.captureMessage(message)
//        } catch (e: Exception) {
//            e.printStackTrace()
//        }
//    }


    // DONT REMOVE, we will bring back this code when we need to verify the signature
    // detect frida
//    private fun detectFridaPort(): Boolean {
//        return try {
//            val socket = Socket()
//            socket.connect(InetSocketAddress("127.0.0.1", 27042), 1000)
//            socket.close()
//            true
//        } catch (e: Exception) {
//            false
//        }
//    }

    // DONT REMOVE, we will bring back this code when we need to verify the signature
//    private fun detectFridaMem(): Boolean {
//        try {
//            val mapsFile = BufferedReader(FileReader("/proc/self/maps"))
//            var isFridaDetected = false
//
//            while (true) {
//                val line = mapsFile.readLine() ?: break
//
//                if (line.contains("frida")) {
//                    isFridaDetected = true
//                    break
//                }
//            }
//
//            mapsFile.close()
//            return isFridaDetected
//        } catch (e: Exception) {
//            e.printStackTrace()
//            return false
//        }
//    }

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
        val didRegisterPasskey =
            sharedPreferences.getBoolean("flutter.did_register_passkey", false)
        if (isThisFirstOnResume && didRegisterPasskey) {

            // skip authentication if the user has already registered the passkey in open app
            isThisFirstOnResume = false
            // this is not conventional way to do this, but we need skip authenticate after user
            // authenticate with passkey
            updateAuthenticationTime()
            return
        }

        if (isEnabled && !isAuthenticate && needsReAuthentication()) {
            val biometricManager = BiometricManager.from(this)
            val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
            if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                == BiometricManager.BIOMETRIC_SUCCESS || keyguardManager.isDeviceSecure
            ) {
                val intent = Intent(this@MainActivity, AuthenticatorActivity::class.java)
                updateAuthenticationTime()
                startActivity(intent)
            }
        }
    }

    private fun updateAuthenticationTime() {
        lastAuthTime = System.currentTimeMillis()
    }

    private fun needsReAuthentication(): Boolean {
        val currentTime = System.currentTimeMillis()
        return (currentTime - lastAuthTime) > authenticationTimeout
    }

    override fun onPause() {
        super.onPause()
        isAuthenticate = false
    }

    // DONT REMOVE, we will bring back this code when we need to verify the signature
//    private fun hasTracerPid(): Boolean {
//        val tracerpid = "TracerPid"
//        try {
//            val file = File("/proc/self/status")
//            val lines = file.readLines()
//            for (line in lines) {
//                if (line.length > tracerpid.length) {
//                    if (line.substring(0, tracerpid.length).equals(tracerpid, ignoreCase = true)) {
//                        val pid = line.substring(tracerpid.length + 1).trim().toInt()
//                        if (pid > 0) {
//                            return true
//                        }
//                        break
//                    }
//                }
//            }
//        } catch (exception: Exception) {
//            println(exception)
//        }
//        return false
//    }
}
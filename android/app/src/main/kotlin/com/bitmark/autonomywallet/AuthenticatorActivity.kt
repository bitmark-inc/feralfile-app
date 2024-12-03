package com.bitmark.autonomy_flutter

import android.app.KeyguardManager
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor

class AuthenticatorActivity : AppCompatActivity() {

    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private lateinit var promptInfo: BiometricPrompt.PromptInfo

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_authentication)

        setupBiometricPrompt()

        authenticate()


        findViewById<View>(R.id.enter_passcode).setOnClickListener {
            authenticate()
        }
    }

    private fun setupBiometricPrompt() {
        executor = ContextCompat.getMainExecutor(this)
        biometricPrompt = BiometricPrompt(this, executor,
            object : BiometricPrompt.AuthenticationCallback() {

                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    MainActivity.isAuthenticate = true
                    finish()
                }
            })

        promptInfo = if (android.os.Build.VERSION.SDK_INT >= 30) {
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Authentication required")
                .setDescription("Authentication for \"Feral File\"")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                .build()
        } else {
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Authentication required")
                .setDescription("Authentication for \"Feral File\"")
                .setDeviceCredentialAllowed(true)
                .build()
        }
    }

    private fun authenticate() {
        val biometricManager = BiometricManager.from(this)
        val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager

        if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            == BiometricManager.BIOMETRIC_SUCCESS || keyguardManager.isDeviceSecure
        ) {
            biometricPrompt.authenticate(promptInfo)
        } else {
            MainActivity.isAuthenticate = true
            finish()
        }
    }
}
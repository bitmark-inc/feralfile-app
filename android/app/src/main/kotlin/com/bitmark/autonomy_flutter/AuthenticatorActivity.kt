package com.bitmark.autonomy_flutter

import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.AppCompatImageView
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


        if (BuildConfig.FLAVOR.equals("inhouse")){
            findViewById<AppCompatImageView>(R.id.logo_authentication).setImageResource(R.drawable.penrose_inhouse)
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
                .setDescription("Authentication for \"Autonomy\"")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                .build()
        } else {
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Authentication required")
                .setDescription("Authentication for \"Autonomy\"")
                .setDeviceCredentialAllowed(true)
                .build()
        }
    }

    private fun authenticate() {
        if (android.os.Build.VERSION.SDK_INT >= 30) {
            val biometricManager = BiometricManager.from(this)
            when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)) {
                BiometricManager.BIOMETRIC_SUCCESS -> biometricPrompt.authenticate(promptInfo)
                else -> {
                }
            }
        } else {
            val biometricManager = BiometricManager.from(this)
            when (biometricManager.canAuthenticate()) {
                BiometricManager.BIOMETRIC_SUCCESS -> biometricPrompt.authenticate(promptInfo)
                else -> {
                }
            }
        }
    }
}
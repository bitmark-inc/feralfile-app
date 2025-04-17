package com.bitmark.autonomy_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.bitmark.autonomywallet.MainActivity

class WidgetClickReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        FileLogger.log(
            "WidgetClickReceiver",
            "Received intent: ${intent?.action}, data: ${intent?.data}"
        )
        if (intent?.action == "app.feralfile.WIDGET_CLICK") {
            FileLogger.log("WidgetClickReceiver", "Opening app...")
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                data = intent.data
            }
            try {
                context?.startActivity(launchIntent)
            } catch (e: Exception) {
                FileLogger.log("WidgetClickReceiver", "Error starting activity: ${e.message}")
            }
        }
    }
}
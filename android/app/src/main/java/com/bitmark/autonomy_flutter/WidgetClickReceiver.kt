package com.bitmark.autonomy_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.bitmark.autonomywallet.MainActivity

class WidgetClickReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "app.feralfile.WIDGET_CLICK") {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context?.startActivity(launchIntent)
        }
    }
}
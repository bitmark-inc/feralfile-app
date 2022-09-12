package com.bitmark.autonomy_flutter

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.branch.referral.Branch
import io.branch.referral.BranchError
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject

class BranchIOPlugin(
    engine: FlutterEngine
) : Branch.BranchReferralInitListener, EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    init {
        val eventChannel = EventChannel(
            engine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )
        eventChannel.setStreamHandler(this)
    }

    fun reInitSession(activity: Activity, intent: Intent) {
        intent.putExtra("branch_force_new_session", true)
        activity.intent = intent
        Branch.sessionBuilder(activity).withCallback(this).reInit()
    }

    fun initSession(activity: Activity, intent: Intent) {
        Branch.sessionBuilder(activity)
            .withCallback(this)
            .withData(intent.data)
            .init()
    }

    override fun onInitFinished(referringParams: JSONObject?, error: BranchError?) {
        if (referringParams != null) {
            val type = (object : TypeToken<Map<String, Any?>>() {}).type
            val event = mapOf(
                "eventName" to "observeDeeplinkParams",
                "params" to gson.fromJson(referringParams.toString(), type)
            )
            eventSink?.success(event)
        } else if (error != null) {
            Log.e(TAG, "[Branch] Error ${error.errorCode} ${error.message}")
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    companion object {
        private val TAG = "BranchIOPlugin"
        private const val CHANNEL_NAME = "branch.io/event"
        private val gson = Gson()
    }
}

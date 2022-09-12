package com.bitmark.autonomy_flutter.app

import android.app.Application
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner

class AutonomyApp : Application(), LifecycleEventObserver {

    override fun onCreate() {
        super.onCreate()
        ProcessLifecycleOwner.get().lifecycle.addObserver(this)
    }

    override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
        isInForeground = event.targetState.isAtLeast(Lifecycle.State.RESUMED)
    }

    companion object {
        var isInForeground: Boolean = false
            private set
    }
}